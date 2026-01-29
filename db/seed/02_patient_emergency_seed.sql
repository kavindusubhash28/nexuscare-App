INSERT INTO users (user_id,first_name,last_name,contact_no1,contact_no2,address,created_at)
VALUES
(gen_random_uuid(),'Kamal','Perera','0771234567','0719876543','Colombo, Sri Lanka',NOW()),
(gen_random_uuid(),'Nimal','Fernando','0782223344',NULL,'Kandy, Sri Lanka',NOW());


-- Insert patient (user_id must exist on users table)
INSERT INTO patients (user_id, nic, date_of_birth, gender,image_url)
VALUES
('601d0ca5-4a78-4c7c-aee8-17631a66dfa6','200012345678', '2000-05-10', 'Female','https://www.example.com/profile/image?id=12345&category=profile/12345.png')
ON CONFLICT DO NOTHING;

-- Insert emergency profile
INSERT INTO emergency_profile (patient_id, contact_name, contact_phone, chornical_conditions, blood_group, allergies, is_public_visible)
VALUES
(
    (SELECT patient_id FROM patients WHERE user_id = '601d0ca5-4a78-4c7c-aee8-17631a66dfa6'),
    'Mother',
    '0771234567',
    'diabetics',
    'O+',
    'Penicillin',
    'true'
)
ON CONFLICT DO NOTHING;
