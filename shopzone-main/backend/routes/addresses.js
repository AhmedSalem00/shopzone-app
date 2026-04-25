const router = require('express').Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');

router.use(auth);

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM addresses WHERE user_id = $1 ORDER BY is_default DESC, created_at DESC',
      [req.user.id]
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { label, full_name, phone, address_line1, address_line2, city, state, zip_code, country, is_default } = req.body;

    if (is_default) {
      await pool.query('UPDATE addresses SET is_default = FALSE WHERE user_id = $1', [req.user.id]);
    }

    const result = await pool.query(
      `INSERT INTO addresses (user_id, label, full_name, phone, address_line1, address_line2, city, state, zip_code, country, is_default)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [req.user.id, label, full_name, phone, address_line1, address_line2, city, state, zip_code, country, is_default || false]
    );
    res.status(201).json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { label, full_name, phone, address_line1, address_line2, city, state, zip_code, country, is_default } = req.body;

    if (is_default) {
      await pool.query('UPDATE addresses SET is_default = FALSE WHERE user_id = $1', [req.user.id]);
    }

    const result = await pool.query(
      `UPDATE addresses SET label=$1, full_name=$2, phone=$3, address_line1=$4, address_line2=$5,
       city=$6, state=$7, zip_code=$8, country=$9, is_default=$10
       WHERE id=$11 AND user_id=$12 RETURNING *`,
      [label, full_name, phone, address_line1, address_line2, city, state, zip_code, country, is_default, req.params.id, req.user.id]
    );
    res.json(result.rows[0]);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM addresses WHERE id = $1 AND user_id = $2', [req.params.id, req.user.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.patch('/:id/default', async (req, res) => {
  try {
    await pool.query('UPDATE addresses SET is_default = FALSE WHERE user_id = $1', [req.user.id]);
    await pool.query('UPDATE addresses SET is_default = TRUE WHERE id = $1 AND user_id = $2', [req.params.id, req.user.id]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;