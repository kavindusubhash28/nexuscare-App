from flask import Blueprint, request, jsonify
from src.utils.db import get_conn
from datetime import date

qr_bp = Blueprint("qr_bp", __name__)

from datetime import date, datetime

def calc_age(dob):
    """
    dob can be:
      - datetime.date / datetime.datetime  
      - string 'YYYY-MM-DD'              
      - int (bad data / wrong column)     
    """
    if not dob:
        return None

    # If dob is already a date/datetime
    if isinstance(dob, datetime):
        dob = dob.date()
    if isinstance(dob, date):
        today = date.today()
        return today.year - dob.year - ((today.month, today.day) < (dob.month, dob.day))

    # If dob is a string
    if isinstance(dob, str):
        try:
            dob_date = datetime.strptime(dob, "%Y-%m-%d").date()
            today = date.today()
            return today.year - dob_date.year - ((today.month, today.day) < (dob_date.month, dob_date.day))
        except Exception:
            return None

    # If dob is int or something unexpected
    return None

@qr_bp.get("/doctor/patients/by-qr")
def get_patient_by_qr():
    """
    Accepts scanned QR value.
    Common setups:
      - QR contains patient_id like PT0001
      - QR contains NIC
      - QR contains stored patient.QR_code string
    """
    qr_value = (request.args.get("qr") or "").strip()
    if not qr_value:
        return jsonify({"error": "qr is required"}), 400

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            # Try match patient_id OR nic OR QR_code field
            cur.execute("""
                SELECT
                    p.patient_id,
                    p.nic,
                    p.date_of_birth,
                    p.gender,
                    p.QR_code,
                    u.name,
                    u.contact_no1,
                    u.contact_no2
                FROM patient p
                JOIN users u ON u.user_id = p.user_id
                WHERE p.patient_id = %s
                   OR p.nic = %s
                   OR p.QR_code = %s
                LIMIT 1
            """, (qr_value, qr_value, qr_value))

            row = cur.fetchone()

        if not row:
            return jsonify({"error": "Patient not found"}), 404

        patient_id, nic, dob, gender, qr_code, name, phone1, phone2 = row[:8]

        return jsonify({
            "patient_id": patient_id,
            "name": name,
            "nic": nic,
            "gender": gender,
            "age": calc_age(dob),
            "date_of_birth": str(dob) if dob else None,
            "phone": phone1,
            "phone_alt": phone2,
            "qr_code": qr_code,
        })
    finally:
        conn.close()


@qr_bp.get("/doctor/patients/search")
def search_patients():
    """
    Search box: Patient ID / NIC / phone / name
    GET /api/doctor/patients/search?q=PT0001
    """
    q = (request.args.get("q") or "").strip()
    if not q:
        return jsonify([])

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            # Use ILIKE for partial match on name/phone
            cur.execute("""
                SELECT
                    p.patient_id,
                    p.nic,
                    p.date_of_birth,
                    p.gender,
                    u.name,
                    u.contact_no1
                FROM patient p
                JOIN users u ON u.user_id = p.user_id
                WHERE p.patient_id = %s
                   OR p.nic = %s
                   OR u.contact_no1 ILIKE %s
                   OR u.contact_no2 ILIKE %s
                   OR u.name ILIKE %s
                ORDER BY u.name ASC
                LIMIT 20
            """, (q, q, f"%{q}%", f"%{q}%", f"%{q}%"))

            rows = cur.fetchall()

        return jsonify([{
            "patient_id": r[0],
            "nic": r[1],
            "age": calc_age(r[2]),
            "gender": r[3],
            "name": r[4],
            "phone": r[5],
        } for r in rows])
    finally:
        conn.close()


@qr_bp.get("/doctor/patients/recent")
def recent_patients():
    """
    Recent patients for doctor.
    Uses medical_record as 'last visit' (best match to consultations).
    GET /api/doctor/patients/recent?doctor_id=DOC0010&limit=10
    """
    doctor_id = (request.args.get("doctor_id") or "").strip()
    limit = int(request.args.get("limit") or 10)

    if not doctor_id:
        return jsonify({"error": "doctor_id is required"}), 400

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            # Last visit per patient for this doctor
            cur.execute("""
                SELECT
                    p.patient_id,
                    u.name,
                    p.nic,
                    p.date_of_birth,
                    p.gender,
                    MAX(mr.visit_date) AS last_visit
                FROM medical_record mr
                JOIN patient p ON p.patient_id = mr.patient_id
                JOIN users u ON u.user_id = p.user_id
                WHERE mr.doctor_id = %s
                GROUP BY p.patient_id, u.name, p.nic, p.date_of_birth, p.gender
                ORDER BY last_visit DESC
                LIMIT %s
            """, (doctor_id, limit))

            rows = cur.fetchall()

        return jsonify([{
            "patient_id": r[0],
            "name": r[1],
            "nic": r[2],
            "age": calc_age(r[3]),
            "gender": r[4],
            "last_visit": str(r[5]) if r[5] else None,
        } for r in rows])
    finally:
        conn.close()