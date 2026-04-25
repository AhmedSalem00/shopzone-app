const router = require('express').Router();
const pool = require('../config/db');

router.get('/', async (req, res) => {
  try {
    const { category_id, search, featured, sort } = req.query;
    let query = `SELECT p.*, COALESCE(
      json_agg(json_build_object('url', pi.image_url, 'is_primary', pi.is_primary)) 
      FILTER (WHERE pi.id IS NOT NULL), '[]'
    ) AS images FROM products p LEFT JOIN product_images pi ON p.id = pi.product_id`;
    const conditions = [];
    const params = [];

    if (category_id) { params.push(category_id); conditions.push(`p.category_id = $${params.length}`); }
    if (featured) { conditions.push('p.is_featured = TRUE'); }
    if (search) { params.push(`%${search}%`); conditions.push(`p.name ILIKE $${params.length}`); }

    if (conditions.length) query += ' WHERE ' + conditions.join(' AND ');
    query += ' GROUP BY p.id';

    if (sort === 'price_asc') query += ' ORDER BY p.price ASC';
    else if (sort === 'price_desc') query += ' ORDER BY p.price DESC';
    else if (sort === 'rating') query += ' ORDER BY p.rating DESC';
    else query += ' ORDER BY p.created_at DESC';

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.*, COALESCE(
        json_agg(json_build_object('url', pi.image_url, 'is_primary', pi.is_primary)) 
        FILTER (WHERE pi.id IS NOT NULL), '[]'
      ) AS images FROM products p LEFT JOIN product_images pi ON p.id = pi.product_id WHERE p.id = $1 GROUP BY p.id`,
      [req.params.id]
    );
    if (!result.rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(result.rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/meta/categories', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM categories ORDER BY name');
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;