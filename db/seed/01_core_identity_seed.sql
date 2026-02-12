-- ===============================
-- Seed Data for users table
-- ===============================

INSERT INTO users (user_id, name, contact_no1, contact_no2, address)
VALUES
('U001', 'System Admin',  '0700000000', NULL, 'NexusCare HQ'),
('U002', 'John Doctor',   '0711111111', NULL, 'Colombo'),
('U003', 'Jane Patient',  '0722222222', NULL, 'Kandy'),
('U004', 'Lanka Lab',     '0733333333', NULL, 'Galle'),
('U005', 'City Pharmacy', '0744444444', NULL, 'Kurunegala')
ON CONFLICT (user_id) DO NOTHING;

