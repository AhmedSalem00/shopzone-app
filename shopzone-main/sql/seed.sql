INSERT INTO categories (name, icon) VALUES
('Electronics', 'devices'),
('Fashion', 'checkroom'),
('Home & Garden', 'home'),
('Sports', 'sports_soccer'),
('Books', 'menu_book');

INSERT INTO products (name, description, price, discount_price, category_id, stock, rating, review_count, is_featured) VALUES
('Wireless Noise-Cancelling Headphones', 'Premium over-ear headphones with ANC and 30hr battery', 299.99, 249.99, 1, 50, 4.7, 234, TRUE),
('Smart Watch Pro', 'Fitness tracker with heart rate, GPS, and AMOLED display', 199.99, NULL, 1, 120, 4.5, 189, TRUE),
('Leather Crossbody Bag', 'Handcrafted genuine leather bag with adjustable strap', 89.99, 69.99, 2, 80, 4.3, 67, FALSE),
('Running Shoes Air Max', 'Lightweight mesh running shoes with responsive cushion', 129.99, 99.99, 4, 200, 4.6, 312, TRUE),
('Minimalist Desk Lamp', 'LED desk lamp with touch dimmer and USB charging port', 49.99, NULL, 3, 300, 4.4, 98, FALSE),
('Classic Denim Jacket', 'Vintage-wash cotton denim jacket, unisex fit', 79.99, NULL, 2, 150, 4.2, 45, FALSE),
('Bluetooth Portable Speaker', 'Waterproof speaker with 360° sound and 12hr battery', 59.99, 44.99, 1, 90, 4.5, 156, TRUE),
('Yoga Mat Premium', 'Non-slip eco-friendly yoga mat, 6mm thick', 39.99, 29.99, 4, 400, 4.8, 210, FALSE),
('Indoor Plant Set', 'Set of 3 low-maintenance indoor plants with ceramic pots', 34.99, NULL, 3, 60, 4.1, 32, FALSE),
('Bestseller Novel Collection', '5-book collection of award-winning contemporary fiction', 44.99, 34.99, 5, 500, 4.6, 88, FALSE);

INSERT INTO product_images (product_id, image_url, is_primary)
SELECT id, 'https://picsum.photos/seed/' || SUBSTR(id::text, 1, 8) || '/400/400', TRUE FROM products;