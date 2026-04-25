const router = require('express').Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');
const adminOnly = require('../middleware/admin');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const uploadDir = path.join(__dirname, '..', 'uploads', 'products');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1e6)}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  },
});

const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  if (allowed.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only JPEG, PNG, WebP, and GIF images are allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

router.post('/product/:productId', auth, adminOnly, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No image provided' });

    const { productId } = req.params;
    const isPrimary = req.body.is_primary === 'true';
    const imageUrl = `/uploads/products/${req.file.filename}`;

    if (isPrimary) {
      await pool.query(
        'UPDATE product_images SET is_primary = FALSE WHERE product_id = $1',
        [productId]
      );
    }

    const maxOrder = await pool.query(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 as next FROM product_images WHERE product_id = $1',
      [productId]
    );

    const result = await pool.query(
      `INSERT INTO product_images (product_id, image_url, is_primary, sort_order)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [productId, imageUrl, isPrimary, maxOrder.rows[0].next]
    );

    res.status(201).json({
      ...result.rows[0],
      full_url: `${req.protocol}://${req.get('host')}${imageUrl}`,
    });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.post('/product/:productId/batch', auth, adminOnly, upload.array('images', 10), async (req, res) => {
  try {
    if (!req.files || !req.files.length) return res.status(400).json({ error: 'No images provided' });

    const { productId } = req.params;
    const results = [];

    const maxOrder = await pool.query(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 as next FROM product_images WHERE product_id = $1',
      [productId]
    );
    let sortOrder = maxOrder.rows[0].next;

    for (const file of req.files) {
      const imageUrl = `/uploads/products/${file.filename}`;
      const result = await pool.query(
        `INSERT INTO product_images (product_id, image_url, is_primary, sort_order)
         VALUES ($1, $2, FALSE, $3) RETURNING *`,
        [productId, imageUrl, sortOrder++]
      );
      results.push({
        ...result.rows[0],
        full_url: `${req.protocol}://${req.get('host')}${imageUrl}`,
      });
    }

    res.status(201).json(results);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.delete('/:imageId', auth, adminOnly, async (req, res) => {
  try {
    const image = await pool.query('SELECT * FROM product_images WHERE id = $1', [req.params.imageId]);
    if (!image.rows.length) return res.status(404).json({ error: 'Image not found' });

    const filePath = path.join(__dirname, '..', image.rows[0].image_url);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);

    await pool.query('DELETE FROM product_images WHERE id = $1', [req.params.imageId]);
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.patch('/:imageId/primary', auth, adminOnly, async (req, res) => {
  try {
    const image = await pool.query('SELECT product_id FROM product_images WHERE id = $1', [req.params.imageId]);
    if (!image.rows.length) return res.status(404).json({ error: 'Image not found' });

    await pool.query('UPDATE product_images SET is_primary = FALSE WHERE product_id = $1', [image.rows[0].product_id]);
    await pool.query('UPDATE product_images SET is_primary = TRUE WHERE id = $1', [req.params.imageId]);

    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/avatar', auth, upload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No image provided' });

    const avatarUrl = `/uploads/products/${req.file.filename}`;
    await pool.query('UPDATE users SET avatar_url = $1 WHERE id = $2', [avatarUrl, req.user.id]);

    res.json({
      avatar_url: avatarUrl,
      full_url: `${req.protocol}://${req.get('host')}${avatarUrl}`,
    });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

module.exports = router;