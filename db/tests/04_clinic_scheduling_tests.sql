-- Member 4: Test Queries (Scheduling Module)


-- 1) Available slots for doctor1
SELECT
  a.available_date,
  a.available_time,
  a.is_available,
  c.clinic_location
FROM availability a
JOIN clinic c ON a.clinic_id = c.clinic_id
JOIN credentials dc ON dc.email = 'doctor1@nexuscare.com'
JOIN staff s ON s.user_id = dc.user_id
WHERE a.doctor_id = s.user_id
ORDER BY a.available_date, a.available_time;

-- 2) Appointments for patient1
SELECT
  ap.appointment_date,
  ap.appointment_time,
  ap.status,
  ap.is_paid,
  c.clinic_location,
  docc.email AS doctor_email
FROM appointment ap
JOIN clinic c ON ap.clinic_id = c.clinic_id
JOIN credentials docc ON docc.user_id = ap.doctor_id        
JOIN credentials pc ON pc.email = 'patient1@nexuscare.com'
JOIN patients p ON p.user_id = pc.user_id
WHERE ap.patient_id = p.patient_id
ORDER BY ap.appointment_date DESC, ap.appointment_time DESC;
