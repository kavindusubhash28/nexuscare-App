SELECT
  order_id,
  patient_id,
  prescription_id,
  total_price,
  created_at
FROM orders
ORDER BY order_id DESC;


SELECT
  po.order_id,
  po.collecting_time,
  po.additional_charge
FROM priority_orders po;


SELECT
  no.order_id,
  no.is_prepared
FROM normal_orders no;


SELECT o.order_id
FROM orders o
LEFT JOIN patients p ON p.patient_id = o.patient_id
WHERE p.patient_id IS NULL;


SELECT o.order_id
FROM orders o
LEFT JOIN prescription pr ON pr.prescription_id = o.prescription_id
WHERE o.prescription_id IS NOT NULL
  AND pr.prescription_id IS NULL;


SELECT
  rr.report_id,
  rr.patient_id,
  rr.doctor_id,
  rr.test_name,
  rr.created_at
FROM recommended_reports rr;


SELECT rr.report_id
FROM recommended_reports rr
LEFT JOIN staff_base sb ON sb.user_id = rr.doctor_id
WHERE sb.user_id IS NULL;

SELECT
  lr.lab_report_id,
  lr.patient_id,
  lr.doctor_id,
  lr.lab_id,
  lr.test_name,
  lr.file_url,
  lr.uploaded_at
FROM lab_reports lr;


SELECT lr.lab_report_id
FROM lab_reports lr
LEFT JOIN staff_base sb ON sb.user_id = lr.doctor_id
WHERE sb.user_id IS NULL;


SELECT lr.lab_report_id
FROM lab_reports lr
LEFT JOIN staff_base sb ON sb.user_id = lr.lab_id
WHERE sb.user_id IS NULL;


SELECT lr.lab_report_id
FROM lab_reports lr
LEFT JOIN patients p ON p.patient_id = lr.patient_id
WHERE p.patient_id IS NULL;


SELECT
  p.patient_id,
  rr.test_name,
  lr.file_url,
  sb_lab.organization AS lab_name
FROM lab_reports lr
JOIN patients p ON p.patient_id = lr.patient_id
JOIN staff_base sb_lab ON sb_lab.user_id = lr.lab_id;