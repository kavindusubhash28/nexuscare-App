-- Get patient with emergency details
SELECT
    CONCAT(u.first_name, ' ' ,u.last_name) AS Full_name,
    p.patient_id,
    p.nic,
    p.date_of_birth,
    p.image_url,
    e.contact_name,
    e.contact_phone,
    e.blood_group,
    e.allergies
FROM patients p
JOIN users u ON u.user_id = p.user_id
JOIN emergency_profile e ON e.patient_id = p.patient_id;

-- Count total patients
SELECT COUNT(*) AS total_patients FROM patients;
