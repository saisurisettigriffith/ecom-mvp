INSERT INTO warehouse (code, name, lat, lng, cutoff_local, pack_hours) VALUES
  ('IE-DUB-1', 'Dublin Fulfillment Center', 53.3478, -6.2597, '17:00:00', 4),
  ('GB-LON-1', 'London Fulfillment Center', 51.5072, -0.1276, '18:00:00', 5)
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO product (sku, title, price_cents, attributes) VALUES
  ('SKU123', 'Wireless Earbuds', 5999, JSON_OBJECT('brand','Sonic','color','Black')),
  ('SKU124', 'Smartwatch', 12999, JSON_OBJECT('brand','Chronos','color','Silver'))
ON DUPLICATE KEY UPDATE title = VALUES(title);

INSERT INTO product_image (product_id, url)
SELECT p.id, CONCAT('https://picsum.photos/seed/', p.sku, '/800/600')
FROM product p
ON DUPLICATE KEY UPDATE url = VALUES(url);

INSERT INTO inventory (sku, warehouse_code, available, reserved)
VALUES
  ('SKU123', 'IE-DUB-1', 25, 0),
  ('SKU123', 'GB-LON-1', 12, 0),
  ('SKU124', 'IE-DUB-1', 18, 0)
ON DUPLICATE KEY UPDATE available = VALUES(available);
