from flask import Blueprint, jsonify, request
from src.utils.db import get_conn
from datetime import date

doctor_bp = Blueprint("doctor_bp", __name__)


@doctor_bp.get("/doctor/dashboard")
def doctor_dashboard():
    doctor_id = request.args.get("doctor_id")
    if not doctor_id:
        return jsonify({"error": "doctor_id required"}), 400

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            # Today appointments
            cur.execute("""
                SELECT COUNT(*)
                FROM appointment
                WHERE doctor_id = %s
                  AND appointment_date = CURRENT_DATE
            """, (doctor_id,))
            today_appointments = cur.fetchone()[0]

            # Patients seen today (medical_record)
            cur.execute("""
                SELECT COUNT(*)
                FROM medical_record
                WHERE doctor_id = %s
                  AND visit_date = CURRENT_DATE
            """, (doctor_id,))
            patients_seen_today = cur.fetchone()[0]

            # Prescriptions issued today (join through record)
            cur.execute("""
                SELECT COUNT(*)
                FROM prescription p
                JOIN medical_record m ON m.record_id = p.record_id
                WHERE m.doctor_id = %s
                  AND DATE(p.created_at) = CURRENT_DATE
            """, (doctor_id,))
            issued_prescriptions = cur.fetchone()[0]

            # Pending labs (best-effort using recommended_reports)
            cur.execute("""
                SELECT COUNT(*)
                FROM recommended_reports rr
                JOIN medical_record m ON m.record_id = rr.medical_record_id
                WHERE m.doctor_id = %s
            """, (doctor_id,))
            pending_labs = cur.fetchone()[0]

        return jsonify({
            "todayAppointments": today_appointments,
            "patientsSeenToday": patients_seen_today,
            "pendingLabs": pending_labs,
            "issuedPrescriptions": issued_prescriptions
        })
    finally:
        conn.close()


@doctor_bp.get("/doctor/profile")
def doctor_profile():
    doctor_id = request.args.get("doctor_id")
    if not doctor_id:
        return jsonify({"error": "doctor_id required"}), 400

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT d.doctor_id, d.license_no, d.nic_no, d.gender, d.specialization,
                       u.user_id, u.name, u.contact_no1, u.contact_no2, u.address
                FROM doctor d
                JOIN users u ON u.user_id = d.user_id
                WHERE d.doctor_id = %s
            """, (doctor_id,))
            row = cur.fetchone()

        if not row:
            return jsonify({"error": "Doctor not found"}), 404

        return jsonify({
            "doctor_id": row[0],
            "license_no": row[1],
            "nic_no": row[2],
            "gender": row[3],
            "specialization": row[4],
            "user": {
                "user_id": row[5],
                "name": row[6],
                "contact_no1": row[7],
                "contact_no2": row[8],
                "address": row[9],
            }
        })
    finally:
        conn.close()

@doctor_bp.get("/doctors/<doctor_id>/appointments")
def doctor_appointments(doctor_id):
    filter_type = request.args.get("filter", "all")
    conn = get_conn()

    try:
        with conn.cursor() as cur:
            base_query = """
                SELECT
                    a.appointment_id,
                    a.appointment_date,
                    a.appointment_time,
                    a.status,
                    u.name
                FROM appointment a
                JOIN patient p ON p.patient_id = a.patient_id
                JOIN users u ON u.user_id = p.user_id
                WHERE a.doctor_id = %s
            """
            params = [doctor_id]

            if filter_type == "today":
                base_query += " AND a.appointment_date = CURRENT_DATE"
            elif filter_type == "upcoming":
                base_query += " AND a.status = 'Waiting'"
            elif filter_type == "completed":
                base_query += " AND a.status = 'Conducted'"
            elif filter_type == "cancelled":
                base_query += " AND a.status = 'Not Conducted'"

            base_query += " ORDER BY a.appointment_date, a.appointment_time"

            cur.execute(base_query, params)
            rows = cur.fetchall()

        return jsonify([
            {
                "appointment_id": r[0],
                "date": str(r[1]),
                "time": str(r[2]),
                "status": r[3],
                "patient_name": r[4]
            } for r in rows
        ])

    finally:
        conn.close()

@doctor_bp.patch("/appointments/<appointment_id>/start")
def start_consultation(appointment_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE appointment
                SET status = 'Ongoing'
                WHERE appointment_id = %s
            """, (appointment_id,))
        conn.commit()
        return jsonify({"message": "Consultation started"})
    finally:
        conn.close()

@doctor_bp.post("/appointments/<appointment_id>/complete")
def complete_consultation(appointment_id):
    data = request.get_json(silent=True) or {}

    diagnosis = data.get("diagnosis")
    notes = data.get("notes")

    if not diagnosis:
        return jsonify({"error": "diagnosis is required"}), 400

    conn = get_conn()
    try:
        conn.autocommit = False
        with conn.cursor() as cur:
            # Get patient & doctor from appointment
            cur.execute("""
                SELECT patient_id, doctor_id
                FROM appointment
                WHERE appointment_id = %s
                FOR UPDATE
            """, (appointment_id,))
            row = cur.fetchone()
            if not row:
                conn.rollback()
                return jsonify({"error": "Appointment not found"}), 404

            patient_id, doctor_id = row[:2]

            # Generate record_id (MR + seq)
            cur.execute("SELECT nextval('medical_rec_seq')")
            seq_val = cur.fetchone()[0]
            record_id = f"MR{int(seq_val):06d}"

            # Insert medical record
            cur.execute("""
                INSERT INTO medical_record
                    (record_id, patient_id, doctor_id, diagnosis, notes, visit_date)
                VALUES
                    (%s, %s, %s, %s, %s, CURRENT_DATE)
            """, (record_id, patient_id, doctor_id, diagnosis, notes))

            # Mark appointment conducted
            cur.execute("""
                UPDATE appointment
                SET status = 'Conducted'
                WHERE appointment_id = %s
            """, (appointment_id,))

        conn.commit()
        return jsonify({
            "message": "Consultation completed",
            "record_id": record_id
        }), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        conn.autocommit = True
        conn.close()

@doctor_bp.get("/doctors/<doctor_id>/prescriptions")
def doctor_prescriptions(doctor_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT
                    p.prescription_id,
                    p.medicine_name,
                    p.dosage,
                    p.status,
                    u.name
                FROM prescription p
                JOIN medical_record mr ON mr.record_id = p.record_id
                JOIN patient pt ON pt.patient_id = mr.patient_id
                JOIN users u ON u.user_id = pt.user_id
                WHERE mr.doctor_id = %s
                ORDER BY p.created_at DESC
            """, (doctor_id,))
            rows = cur.fetchall()

        return jsonify([
            {
                "prescription_id": r[0],
                "medicine": r[1],
                "dosage": r[2],
                "status": r[3],
                "patient_name": r[4]
            } for r in rows
        ])
    finally:
        conn.close()

@doctor_bp.post("/medical-record/<record_id>/prescription")
def create_prescription(record_id):
    data = request.get_json(silent=True) or {}

    medicine_name = data.get("medicine_name")
    dosage = data.get("dosage")
    frequency = data.get("frequency")
    duration_days = data.get("duration_days")

    if not medicine_name or not dosage:
        return jsonify({"error": "medicine_name and dosage are required"}), 400

    conn = get_conn()
    try:
        conn.autocommit = False
        with conn.cursor() as cur:
            # Validate record exists (avoid FK 500)
            cur.execute("SELECT 1 FROM medical_record WHERE record_id = %s", (record_id,))
            if not cur.fetchone():
                conn.rollback()
                return jsonify({"error": f"record_id {record_id} not found"}), 404

            # Generate prescription_id (RX + seq)
            cur.execute("SELECT nextval('prescription_seq')")
            seq_val = cur.fetchone()[0]
            prescription_id = f"RX{int(seq_val):06d}"

            cur.execute("""
                INSERT INTO prescription
                    (prescription_id, record_id, medicine_name, dosage, frequency, duration_days, status)
                VALUES
                    (%s, %s, %s, %s, %s, %s, 'Issued')
            """, (prescription_id, record_id, medicine_name, dosage, frequency, duration_days))

        conn.commit()
        return jsonify({
            "message": "Prescription created",
            "prescription_id": prescription_id
        }), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        conn.autocommit = True
        conn.close()

@doctor_bp.post("/medical-record/<record_id>/lab-request")
def request_lab(record_id):
    data = request.get_json()
    conn = get_conn()

    try:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO recommended_reports
                (medical_record_id, lab_id, test_name)
                VALUES (%s, %s, %s)
            """, (
                record_id,
                data["lab_id"],
                data["test_name"]
            ))

        conn.commit()
        return jsonify({"message": "Lab request created"})
    finally:
        conn.close()

