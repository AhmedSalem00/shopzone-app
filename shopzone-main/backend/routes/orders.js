const router = require('express').Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');

router.use(auth);

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT o.*, json_agg(json_build_object(
        'product_name', p.name, 'quantity', oi.quantity, 'unit_price', oi.unit_price
      )) AS items FROM orders o
       JOIN order_items oi ON o.id = oi.order_id
       JOIN products p ON oi.product_id = p.id
       WHERE o.user_id = $1 GROUP BY o.id ORDER BY o.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { address_id, payment_method } = req.body;

    const cart = await client.query(
      `SELECT ci.*, p.price, p.discount_price, p.stock FROM cart_items ci
       JOIN products p ON ci.product_id = p.id WHERE ci.user_id = $1`,
      [req.user.id]
    );
    if (!cart.rows.length) throw new Error('Cart is empty');

    const subtotal = cart.rows.reduce((sum, item) => {
      const price = item.discount_price || item.price;
      return sum + price * item.quantity;
    }, 0);
    const shipping = subtotal > 50 ? 0 : 5.99;

    const order = await client.query(
      `INSERT INTO orders (user_id, address_id, subtotal, shipping_fee, total, payment_method)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [req.user.id, address_id, subtotal, shipping, subtotal + shipping, payment_method]
    );

    for (const item of cart.rows) {
      if (item.quantity > item.stock) throw new Error(`Insufficient stock for product`);
      await client.query(
        'INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES ($1,$2,$3,$4)',
        [order.rows[0].id, item.product_id, item.quantity, item.discount_price || item.price]
      );
      await client.query('UPDATE products SET stock = stock - $1 WHERE id = $2', [item.quantity, item.product_id]);
    }

    await client.query('DELETE FROM cart_items WHERE user_id = $1', [req.user.id]);
    await client.query('COMMIT');

    res.status(201).json(order.rows[0]);
  } catch (e) {
    await client.query('ROLLBACK');
    res.status(400).json({ error: e.message });
  } finally {
    client.release();
  }
});

module.exports = router;