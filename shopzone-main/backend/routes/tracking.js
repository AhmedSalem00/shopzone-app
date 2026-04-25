const router = require('express').Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');

router.use(auth);

router.get('/:orderId', async (req, res) => {
  try {
    const order = await pool.query(
      `SELECT o.*, a.address_line1, a.city, a.country,
       json_agg(json_build_object(
         'product_name', p.name, 'quantity', oi.quantity, 
         'unit_price', oi.unit_price,
         'image', (SELECT image_url FROM product_images WHERE product_id = p.id AND is_primary LIMIT 1)
       )) AS items
       FROM orders o
       LEFT JOIN addresses a ON o.address_id = a.id
       JOIN order_items oi ON o.id = oi.order_id
       JOIN products p ON oi.product_id = p.id
       WHERE o.id = $1 AND o.user_id = $2
       GROUP BY o.id, a.address_line1, a.city, a.country`,
      [req.params.orderId, req.user.id]
    );
    if (!order.rows.length) return res.status(404).json({ error: 'Order not found' });

    const tracking = await pool.query(
      'SELECT * FROM order_tracking WHERE order_id = $1 ORDER BY created_at ASC',
      [req.params.orderId]
    );

    res.json({ order: order.rows[0], tracking: tracking.rows });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT o.*,
       (SELECT json_agg(json_build_object('product_name', p.name, 'quantity', oi.quantity, 'unit_price', oi.unit_price,
         'image', (SELECT image_url FROM product_images WHERE product_id = p.id AND is_primary LIMIT 1)))
        FROM order_items oi JOIN products p ON oi.product_id = p.id WHERE oi.order_id = o.id) AS items,
       (SELECT title FROM order_tracking WHERE order_id = o.id ORDER BY created_at DESC LIMIT 1) AS latest_tracking
       FROM orders o WHERE o.user_id = $1 ORDER BY o.created_at DESC`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;