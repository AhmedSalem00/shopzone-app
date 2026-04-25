ALTER TABLE orders ADD COLUMN IF NOT EXISTS stripe_payment_intent_id VARCHAR(255);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS stripe_client_secret VARCHAR(255);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_status VARCHAR(30) DEFAULT 'pending';

CREATE TABLE IF NOT EXISTS device_tokens (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform VARCHAR(20) DEFAULT 'android',
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);

ALTER TABLE reviews ADD COLUMN IF NOT EXISTS title VARCHAR(255);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS helpful_count INT DEFAULT 0;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS verified_purchase BOOLEAN DEFAULT FALSE;

ALTER TABLE addresses ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS full_name VARCHAR(100);
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);

CREATE TABLE IF NOT EXISTS order_tracking (
    id SERIAL PRIMARY KEY,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE orders ADD COLUMN IF NOT EXISTS tracking_number VARCHAR(100);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS estimated_delivery TIMESTAMP;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP;

ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'customer';

INSERT INTO users (email, password_hash, full_name, role)
VALUES ('admin@shopzone.com', '$2a$10$8KzQrY8e5YQfR9K8vXzQXeJxZv1qZ5yW3kN7mG5pLhR2dX4wC6S8i', 'Admin User', 'admin')
ON CONFLICT (email) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_order_tracking_order ON order_tracking(order_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);