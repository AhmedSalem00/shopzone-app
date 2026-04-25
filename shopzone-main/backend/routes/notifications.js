const router = require('express').Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');
const admin = require('firebase-admin');

let firebaseInitialized = false;
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    firebaseInitialized = true;
    console.log('Firebase initialized');
  }
} catch (e) {
  console.log('Firebase not configured - notifications disabled');
}

router.post('/register-token', auth, async (req, res) => {
  try {
    const { token, platform } = req.body;
    await pool.query(
      `INSERT INTO device_tokens (user_id, fcm_token, platform)
       VALUES ($1, $2, $3) ON CONFLICT (user_id, fcm_token) DO NOTHING`,
      [req.user.id, token, platform || 'android']
    );
    res.json({ success: true });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.delete('/remove-token', auth, async (req, res) => {
  try {
    const { token } = req.body;
    await pool.query(
      'DELETE FROM device_tokens WHERE user_id = $1 AND fcm_token = $2',
      [req.user.id, token]
    );
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

async function sendNotification(userId, title, body, data = {}) {
  if (!firebaseInitialized) return;

  try {
    const tokens = await pool.query(
      'SELECT fcm_token FROM device_tokens WHERE user_id = $1',
      [userId]
    );

    if (!tokens.rows.length) return;

    const messages = tokens.rows.map(t => ({
      token: t.fcm_token,
      notification: { title, body },
      data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
    }));

    for (const msg of messages) {
      try {
        await admin.messaging().send(msg);
      } catch (e) {
        if (e.code === 'messaging/registration-token-not-registered') {
          await pool.query('DELETE FROM device_tokens WHERE fcm_token = $1', [msg.token]);
        }
      }
    }
  } catch (e) {
    console.error('Notification error:', e.message);
  }
}

router.notifyOrderUpdate = async (userId, orderId, status) => {
  const titles = {
    confirmed: '✅ Order Confirmed',
    processing: '📦 Order Being Prepared',
    shipped: '🚚 Order Shipped',
    out_for_delivery: '🏃 Out for Delivery',
    delivered: '🎉 Order Delivered',
    cancelled: '❌ Order Cancelled',
  };

  await sendNotification(
    userId,
    titles[status] || 'Order Update',
    `Your order #${orderId.slice(0, 8)} has been updated.`,
    { order_id: orderId, status }
  );
};

module.exports = router;