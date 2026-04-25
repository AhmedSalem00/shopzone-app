const router = require('express').Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');

router.get('/product/:productId', async (req, res) => {
  try {
    const { sort } = req.query;
    let orderBy = 'r.created_at DESC';
    if (sort === 'rating_high') orderBy = 'r.rating DESC';
    else if (sort === 'rating_low') orderBy = 'r.rating ASC';
    else if (sort === 'helpful') orderBy = 'r.helpful_count DESC';

    const result = await pool.query(
      `SELECT r.*, u.full_name, u.avatar_url
       FROM reviews r JOIN users u ON r.user_id = u.id
       WHERE r.product_id = $1 ORDER BY ${orderBy}`,
      [req.params.productId]
    );

    const stats = await pool.query(
      `SELECT rating, COUNT(*)::int as count FROM reviews 
       WHERE product_id = $1 GROUP BY rating ORDER BY rating DESC`,
      [req.params.productId]
    );

    res.json({ reviews: result.rows, stats: stats.rows });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/', auth, async (req, res) => {
  try {
    const { product_id, rating, title, comment } = req.body;

    const existing = await pool.query(
      'SELECT id FROM reviews WHERE user_id = $1 AND product_id = $2',
      [req.user.id, product_id]
    );
    if (existing.rows.length) return res.status(400).json({ error: 'Already reviewed this product' });

    const purchased = await pool.query(
      `SELECT 1 FROM order_items oi JOIN orders o ON oi.order_id = o.id
       WHERE o.user_id = $1 AND oi.product_id = $2 AND o.status != 'cancelled'`,
      [req.user.id, product_id]
    );

    const result = await pool.query(
      `INSERT INTO reviews (user_id, product_id, rating, title, comment, verified_purchase)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [req.user.id, product_id, rating, title, comment, purchased.rows.length > 0]
    );

    await pool.query(
      `UPDATE products SET 
         rating = (SELECT ROUND(AVG(rating)::numeric, 1) FROM reviews WHERE product_id = $1),
         review_count = (SELECT COUNT(*) FROM reviews WHERE product_id = $1)
       WHERE id = $1`,
      [product_id]
    );

    res.status(201).json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.post('/:id/helpful', auth, async (req, res) => {
  try {
    await pool.query('UPDATE reviews SET helpful_count = helpful_count + 1 WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;