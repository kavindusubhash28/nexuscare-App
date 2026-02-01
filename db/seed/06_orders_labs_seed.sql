
INSERT INTO orders (patient_id, prescription_id, total_price)
SELECT
  p.patient_id,
  pr.prescription_id,
  2500.00
FROM patients p
JOIN prescription pr ON TRUE
LIMIT 1
ON CONFLICT DO NOTHING;


INSERT INTO priority_orders (order_id, collecting_time, additional_charge)
SELECT
  o.order_id,
  INTERVAL '2 hours',
  500.00
FROM orders o
ORDER BY o.order_id DESC
LIMIT 1
ON CONFLICT DO NOTHING;


INSERT INTO normal_orders (order_id, is_prepared)
SELECT
  o.order_id,
  TRUE
FROM orders o
ORDER BY o.order_id DESC
LIMIT 1
ON CONFLICT DO NOTHING;


INSERT INTO recommended_reports (patient_id, doctor_id, test_name)
SELECT
  p.patient_id,
  d.user_id,
  'Blood Sugar'
FROM patients p
JOIN doctors d ON TRUE
LIMIT 1
ON CONFLICT DO NOTHING;


INSERT INTO lab_reports (patient_id, doctor_id, lab_id, test_name, file_url)
SELECT
  p.patient_id,
  d.user_id,
  l.user_id,
  'Blood Sugar',
  'https://example.com/lab_report_001.pdf'
FROM patients p
JOIN doctors d ON TRUE
JOIN labs l ON TRUE
LIMIT 1
ON CONFLICT DO NOTHING;