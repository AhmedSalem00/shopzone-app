const router = require('express').Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');
const adminOnly = require('../middleware/admin');
const notifications = require('./notifications');

router.use(auth);
router.use(adminOnly);

router.get('/stats', async (req, res) => {
  try {
    const [revenue, orders, users, products] = await Promise.all([
      pool.query(`SELECT COALESCE(SUM(total), 0) as total_revenue, 
        COALESCE(SUM(CASE WHEN created_at > NOW() - INTERVAL '30 days' THEN total END), 0) as monthly_revenue
        FROM orders WHERE payment_status = 'paid'`),
      pool.query(`SELECT COUNT(*)::int as total,
        COUNT(CASE WHEN status = 'pending' THEN 1 END)::int as pending,
        COUNT(CASE WHEN status = 'confirmed' THEN 1 END)::int as confirmed,
        COUNT(CASE WHEN status = 'shipped' THEN 1 END)::int as shipped,
        COUNT(CASE WHEN status = 'delivered' THEN 1 END)::int as delivered
        FROM orders`),
      pool.query(`SELECT COUNT(*)::int as total,
        COUNT(CASE WHEN created_at > NOW() - INTERVAL '30 days' THEN 1 END)::int as new_this_month
        FROM users WHERE role = 'customer'`),
      pool.query(`SELECT COUNT(*)::int as total,
        COUNT(CASE WHEN stock < 10 THEN 1 END)::int as low_stock
        FROM products`),
    ]);

    res.json({
      revenue: revenue.rows[0],
      orders: orders.rows[0],
      users: users.rows[0],
      products: products.rows[0],
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/stats/revenue-chart', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT TO_CHAR(DATE_TRUNC('month', created_at), 'YYYY-MM') as month,
       COALESCE(SUM(total), 0)::float as revenue, COUNT(*)::int as order_count
       FROM orders WHERE payment_status = 'paid' AND created_at > NOW() - INTERVAL '12 months'
       GROUP BY DATE_TRUNC('month', created_at)
       ORDER BY month ASC`
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/orders', async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let query = `SELECT o.*, u.full_name as customer_name, u.email as customer_email
      FROM orders o JOIN users u ON o.user_id = u.id`;
    const params = [];

    if (status) {
      params.push(status);
      query += ` WHERE o.status = $${params.length}`;
    }

    query += ' ORDER BY o.created_at DESC';
    params.push(limit, offset);
    query += ` LIMIT $${params.length - 1} OFFSET $${params.length}`;

    const result = await pool.query(query, params);
    const count = await pool.query('SELECT COUNT(*)::int FROM orders' + (status ? ' WHERE status = $1' : ''), status ? [status] : []);

    res.json({ orders: result.rows, total: count.rows[0].count });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.patch('/orders/:id/status', async (req, res) => {
  try {
    const { status, tracking_number, estimated_delivery } = req.body;

    const statusTitles = {
      confirmed: 'Order Confirmed',
      processing: 'Being Prepared',
      shipped: 'Shipped',
      out_for_delivery: 'Out for Delivery',
      delivered: 'Delivered',
      cancelled: 'Cancelled',
    };

    const updates = ['status = $1'];
    const params = [status, req.params.id];

    if (tracking_number) { params.push(tracking_number); updates.push(`tracking_number = $${params.length}`); }
    if (estimated_delivery) { params.push(estimated_delivery); updates.push(`estimated_delivery = $${params.length}`); }
    if (status === 'delivered') updates.push('delivered_at = NOW()');

    await pool.query(`UPDATE orders SET ${updates.join(', ')}, updated_at = NOW() WHERE id = $2`, params);

    await pool.query(
      `INSERT INTO order_tracking (order_id, status, title, description)
       VALUES ($1, $2, $3, $4)`,
      [req.params.id, status, statusTitles[status] || status, req.body.description || `Order status updated to ${status}`]
    );

    const order = await pool.query('SELECT user_id FROM orders WHERE id = $1', [req.params.id]);
    if (order.rows.length) {
      await notifications.notifyOrderUpdate(order.rows[0].user_id, req.params.id, status);
    }

    res.json({ success: true });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.get('/products', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.*, c.name as category_name FROM products p
       LEFT JOIN categories c ON p.category_id = c.id ORDER BY p.created_at DESC`
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/products', async (req, res) => {
  try {
    const { name, description, price, discount_price, category_id, stock, is_featured } = req.body;
    const result = await pool.query(
      `INSERT INTO products (name, description, price, discount_price, category_id, stock, is_featured)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [name, description, price, discount_price, category_id, stock, is_featured]
    );
    res.status(201).json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.put('/products/:id', async (req, res) => {
  try {
    const { name, description, price, discount_price, category_id, stock, is_featured } = req.body;
    const result = await pool.query(
      `UPDATE products SET name=$1, description=$2, price=$3, discount_price=$4, 
       category_id=$5, stock=$6, is_featured=$7, updated_at=NOW() WHERE id=$8 RETURNING *`,
      [name, description, price, discount_price, category_id, stock, is_featured, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.delete('/products/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM products WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/users', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, email, full_name, phone, role, created_at,
       (SELECT COUNT(*)::int FROM orders WHERE user_id = users.id) as order_count
       FROM users ORDER BY created_at DESC`
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;