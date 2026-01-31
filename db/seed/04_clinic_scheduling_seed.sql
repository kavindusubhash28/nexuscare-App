-- Member 4: Seed Scheduling Data (Clinic + Availability + Appointment)



-- 1) Create clinic (safe re-run WITHOUT needing a UNIQUE constraint)
INSERT INTO clinic (clinic_location, has_clinic_management)
SELECT 'Colombo General Clinic', TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM clinic WHERE clinic_location = 'Colombo General Clinic'
);

-- 2) Availability slot 1 (10:00) - safe re-run
INSERT INTO availability (doctor_id, clinic_id, available_date, available_time, is_available)
SELECT
  s.user_id,
  c.clinic_id,
  (CURRENT_DATE + INTERVAL '1 day')::date,
  TIME '10:00',
  TRUE
FROM clinic c
JOIN credentials dc ON dc.email = 'doctor1@nexuscare.com'   
JOIN staff s ON s.user_id = dc.user_id                      
WHERE c.clinic_location = 'Colombo General Clinic'
ON CONFLICT (doctor_id, clinic_id, available_date, available_time) DO NOTHING;

-- 3) Availability slot 2 (11:00) - safe re-run
INSERT INTO availability (doctor_id, clinic_id, available_date, available_time, is_available)
SELECT
  s.user_id,
  c.clinic_id,
  (CURRENT_DATE + INTERVAL '1 day')::date,
  TIME '11:00',
  TRUE
FROM clinic c
JOIN credentials dc ON dc.email = 'doctor1@nexuscare.com'
JOIN staff s ON s.user_id = dc.user_id
WHERE c.clinic_location = 'Colombo General Clinic'
ON CONFLICT (doctor_id, clinic_id, available_date, available_time) DO NOTHING;

-- 4) Create 1 appointment (patient1 books 10:00) - safe re-run
INSERT INTO appointment (patient_id, doctor_id, clinic_id, appointment_date, appointment_time, status, is_paid)
SELECT
  p.patient_id,                 
  s.user_id,                    
  c.clinic_id,
  (CURRENT_DATE + INTERVAL '1 day')::date,
  TIME '10:00',
  'BOOKED',
  FALSE
FROM clinic c
JOIN credentials pc ON pc.email = 'patient1@nexuscare.com'
JOIN patients p ON p.user_id = pc.user_id                   
JOIN credentials dc ON dc.email = 'doctor1@nexuscare.com'
JOIN staff s ON s.user_id = dc.user_id
WHERE c.clinic_location = 'Colombo General Clinic'
ON CONFLICT DO NOTHING;

-- 5) Mark booked slot unavailable (recommended)
UPDATE availability a
SET is_available = FALSE
FROM clinic c
JOIN credentials dc ON dc.email = 'doctor1@nexuscare.com'
JOIN staff s ON s.user_id = dc.user_id
WHERE a.doctor_id = s.user_id
  AND a.clinic_id = c.clinic_id
  AND c.clinic_location = 'Colombo General Clinic'
  AND a.available_date = (CURRENT_DATE + INTERVAL '1 day')::date
  AND a.available_time = TIME '10:00';
