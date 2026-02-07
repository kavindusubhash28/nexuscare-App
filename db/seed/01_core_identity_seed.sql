-- 1. INSERT USERS (Parent Records)
-- Triggers will automatically generate user_id (e.g., NEX000001)
INSERT INTO users (first_name, last_name, contact_no1, contact_no2, address, created_at)
VALUES 
    ('Saman', 'Kumara', '0771111111', NULL, '123 Galle Rd, Colombo', NOW()), -- Patient
    ('Dr. Nimal', 'Perera', '0772222222', '0112222222', '45 Kandy Rd, Kandy', NOW()), -- Doctor
    ('City', 'Pharmacy', '0773333333', NULL, '89 Main St, Galle', NOW()), -- Pharmacy
    ('Super', 'Admin', '0774444444', NULL, 'Nexus HQ, Colombo', NOW()), -- Admin
    ('Asiri', 'Labs', '0775555555', NULL, 'Lab Complex, Colombo', NOW()); -- Lab
    
