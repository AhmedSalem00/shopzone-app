const router = require('express').Router();
const pool = require('../config/db');
const auth = require('../middleware/auth');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

router.use(auth);

router.post('/create-payment-intent', async (req, res) => {
  try {
    const { order_id } = req.body;

    const order = await pool.query('SELECT * FROM orders WHERE id = $1 AND user_id = $2', [order_id, req.user.id]);
    if (!order.rows.length) return res.status(404).json({ error: 'Order not found' });

    const amount = Math.round(order.rows[0].total * 100); // cents

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: 'usd',
      metadata: { order_id, user_id: req.user.id },
    });

    await pool.query(
      'UPDATE orders SET stripe_payment_intent_id = $1, stripe_client_secret = $2 WHERE id = $3',
      [paymentIntent.id, paymentIntent.client_secret, order_id]
    );

    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.post('/confirm', async (req, res) => {
  try {
    const { order_id, payment_intent_id } = req.body;

    const intent = await stripe.paymentIntents.retrieve(payment_intent_id);
    if (intent.status !== 'succeeded') {
      return res.status(400).json({ error: 'Payment not completed' });
    }

    await pool.query(
      `UPDATE orders SET payment_status = 'paid', status = 'confirmed' WHERE id = $1`,
      [order_id]
    );

    await pool.query(
      `INSERT INTO order_tracking (order_id, status, title, description)
       VALUES ($1, 'confirmed', 'Order Confirmed', 'Your payment has been received and order is confirmed')`,
      [order_id]
    );

    res.json({ success: true });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.post('/webhook', require('express').raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  try {
    const event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);

    if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object;
      await pool.query(
        `UPDATE orders SET payment_status = 'paid', status = 'confirmed' 
         WHERE stripe_payment_intent_id = $1`,
        [paymentIntent.id]
      );
    }

    res.json({ received: true });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

module.exports = router;