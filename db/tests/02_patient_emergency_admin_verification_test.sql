
_________-tests-______________


SELECT 
    p.patient_id,
    u.first_name || ' ' || u.last_name AS patient_name,
    e.blood_group,
    e.allergies,
    e.contact_phone AS emergency_contact
FROM patient p
JOIN users u ON p.user_id = u.user_id
JOIN emergency_profile e ON p.patient_id = e.patient_id;

SELECT 
    a.appointment_id,
    a.appointment_date,
    a.status,
    pat_u.first_name AS patient_name,
    doc_u.last_name AS doctor_name,
    c.clinic_location
FROM appointment a
JOIN patient p ON a.patient_id = p.patient_id
JOIN users pat_u ON p.user_id = pat_u.user_id
JOIN doctor d ON a.doctor_id = d.doctor_id
JOIN users doc_u ON d.user_id = doc_u.user_id
JOIN clinic c ON a.clinic_id = c.clinic_id;

SELECT 
    pr.medicine_name,
    pr.dosage,
    pr.status AS prescription_status,
    pharm_u.first_name AS pharmacy_name,
    po.total_price
FROM prescription pr
JOIN priority_order po ON pr.prescription_id = po.prescription_id
JOIN pharmacy ph ON po.pharmacy_id = ph.pharmacy_id
JOIN users pharm_u ON ph.user_id = pharm_u.user_id;


SELECT 'User ID' as type, user_id, first_name FROM users
UNION ALL
SELECT 'Patient ID', patient_id, nic FROM patient
UNION ALL
SELECT 'Doctor ID', doctor_id, license_no FROM doctor;