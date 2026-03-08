from flask import Flask, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from pathlib import Path
from dotenv import load_dotenv
from db import get_main_db, get_auth_db

BASE_DIR = Path(__file__).resolve().parent
env_path = BASE_DIR / ".env"

load_dotenv(dotenv_path=env_path)

app = Flask(__name__)
CORS(app)

# =====================================
# DASHBOARD STATS
# =====================================
@app.route("/admin/dashboard", methods=["GET"])
def dashboard():
    try:
        conn = get_main_db()
        cur = conn.cursor()

        cur.execute("SELECT COUNT(*) FROM patient;")
        patients = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM doctor;")
        doctors = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM pharmacy;")
        pharmacies = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM lab;")
        labs = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM appointment;")
        appointments = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM doctor WHERE verification_status='Pending';")
        pending_doctors = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM pharmacy WHERE verification_status='Pending';")
        pending_pharmacies = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM lab WHERE verification_status='Pending';")
        pending_labs = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM doctor WHERE verification_status='Approved';")
        available_doctors = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM pharmacy WHERE verification_status='Approved';")
        available_pharmacies = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM lab WHERE verification_status='Approved';")
        available_labs = cur.fetchone()["count"]

        cur.close()
        conn.close()

        return jsonify({
            "totalPatients": patients,
            "pendingRequests": pending_doctors + pending_pharmacies + pending_labs,
            "totalDoctors": available_doctors,
            "totalPharmacies": available_pharmacies,
            "totalLabs": available_labs,
            "totalAppointments": appointments
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# =====================================
# DOCTORS
# =====================================
@app.route("/admin/doctors", methods=["GET"])
def doctors():
    try:
        conn = get_main_db()
        cur = conn.cursor()

        cur.execute("""
            SELECT 
                d.doctor_id AS id,
                u.name,
                d.specialization AS type,
                d.license_no AS license,
                d.verification_status AS status,
                d.gender,
                d.nic_no,
                u.contact_no1,
                u.contact_no2,
                u.address,
                d.image_url AS "imageURL",
                d.certification_url AS "certificationURL"
            FROM doctor d
            JOIN users u ON d.user_id = u.user_id
            WHERE d.verification_status = 'Pending';
        """)

        doctors = cur.fetchall()
        cur.close()
        conn.close()

        return jsonify(doctors)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# =====================================
# LABS
# =====================================
@app.route("/admin/labs", methods=["GET"])
def labs():
    try:
        conn = get_main_db()
        cur = conn.cursor()

        cur.execute("""
            SELECT 
                l.lab_id AS id,
                u.name AS name,
                u.address,
                u.contact_no1,
                u.contact_no2,
                l.license_no AS license,
                l.business_registration_number AS br_no,
                l.business_registration_url AS br_url,
                l.available_tests,
                l.verification_status AS status
            FROM lab l
            JOIN users u ON l.user_id = u.user_id
            WHERE l.verification_status = 'Pending';
        """)

        labs = cur.fetchall()
        cur.close()
        conn.close()

        return jsonify(labs)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# =====================================
# PHARMACIES
# =====================================
@app.route("/admin/pharmacies", methods=["GET"])
def pharmacies():
    try:
        conn = get_main_db()
        cur = conn.cursor()

        cur.execute("""
            SELECT 
                p.pharmacy_id AS id,
                u.name AS name,
                u.address,
                u.contact_no1,
                u.contact_no2,
                p.pharmacy_license_no AS license,
                p.business_registration_number AS br_no,
                p.business_registration_url AS br_url,
                p.verification_status AS status
            FROM pharmacy p
            JOIN users u ON p.user_id = u.user_id
            WHERE p.verification_status = 'Pending';
        """)

        pharmacies = cur.fetchall()
        cur.close()
        conn.close()

        return jsonify(pharmacies)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ===============================
# ALL USERS (Categorized)
# ===============================
@app.route("/admin/users/<role>", methods=["GET"])
def get_users(role):

    conn = get_main_db()
    cur = conn.cursor()

    role_map = {
        "patient": """
    SELECT 
        p.patient_id AS "subId",
        u.name AS "name",
        u.user_id AS "userId"
    FROM patient p
    JOIN users u ON p.user_id = u.user_id;
""",

"doctor": """
    SELECT 
        d.doctor_id AS "subId",
        u.name AS "name",
        u.user_id AS "userId",
        d.verification_status AS "status"
    FROM doctor d
    JOIN users u ON d.user_id = u.user_id;
""",

"pharmacy": """
    SELECT 
        p.pharmacy_id AS "subId",
        u.name AS "name",
        u.user_id AS "userId",
        p.verification_status AS "status"
    FROM pharmacy p
    JOIN users u ON p.user_id = u.user_id;
""",

"lab": """
    SELECT 
        l.lab_id AS "subId",
        u.name AS "name",
        u.user_id AS "userId",
        l.verification_status AS "status"
    FROM lab l
    JOIN users u ON l.user_id = u.user_id;
"""
    }
    
    if role not in role_map:
        return jsonify({"error": "Invalid role"}), 400

    cur.execute(role_map[role])
    rows = cur.fetchall()

    cur.close()
    conn.close()

    # -------- CHECK LOGIN STATUS FROM AUTH DB --------
    if role == "patient":

        auth_conn = get_auth_db()
        auth_cur = auth_conn.cursor()

        for row in rows:

            auth_cur.execute(
                "SELECT is_active FROM credentials WHERE user_id = %s",
                (row["userId"],)
            )

            result = auth_cur.fetchone()

            if result and result["is_active"]:
                row["status"] = "Active"
            else:
                row["status"] = "Disabled"

        auth_cur.close()
        auth_conn.close()

    return jsonify(rows)

# =====================================
# UPDATE STATUS
# =====================================
@app.route("/admin/update/<role>/<id>/<status>", methods=["POST"])
def update(role, id, status):

    if status not in ["Approved", "Rejected"]:
        return jsonify({"error": "Invalid status"}), 400

    table_map = {
        "doctor": ("doctor", "doctor_id"),
        "lab": ("lab", "lab_id"),
        "pharmacy": ("pharmacy", "pharmacy_id")
    }

    if role not in table_map:
        return jsonify({"error": "Invalid role"}), 400

    try:
        conn = get_main_db()
        cur = conn.cursor()

        table, id_column = table_map[role]

        cur.execute(
            f"UPDATE {table} SET verification_status=%s WHERE {id_column}=%s;",
            (status, id)
        )

        conn.commit()
        cur.close()
        conn.close()

        return jsonify({"message": "Updated successfully"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

# =====================================
# USER FULL DETAILS
# =====================================
@app.route("/admin/user-details/<role>/<user_id>", methods=["GET"])
def user_details(role, user_id):
    try:
        conn = get_main_db()
        cur = conn.cursor()

        if role == "patient":
            cur.execute("""
                SELECT *
                FROM users u
                JOIN patient p ON u.user_id = p.user_id
                WHERE u.user_id = %s;
            """, (user_id,))

        elif role == "doctor":
            cur.execute("""
                SELECT *
                FROM users u
                JOIN doctor d ON u.user_id = d.user_id
                WHERE u.user_id = %s;
            """, (user_id,))

        elif role == "pharmacy":
            cur.execute("""
                SELECT p.pharmacy_id, p.pharmacy_license_no,p.business_registration_number, p.business_registration_url,p.available_date, p.verification_status,u.name, u.contact_no1, u.contact_no2, u.address, u.created_at
                FROM users u
                JOIN pharmacy p ON u.user_id = p.user_id
                WHERE u.user_id = %s;
            """, (user_id,))

        elif role == "lab":
            cur.execute("""
                SELECT l.lab_id, l.user_id, l.license_no, business_registration_number, l.business_registration_url, l.available_tests, l.verification_status, u.name, u.contact_no1, u.contact_no2, u.address, u.created_at
                FROM users u
                JOIN lab l ON u.user_id = l.user_id
                WHERE u.user_id = %s;
            """, (user_id,))

        else:
            return jsonify({"error": "Invalid role"}), 400

        data = cur.fetchone()

        cur.close()
        conn.close()

        return jsonify(data)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# =====================================
# DELETE USER LOGIN (AUTH DATABASE)
# =====================================
@app.route("/admin/delete-login/<user_id>", methods=["DELETE"])
def delete_user_login(user_id):
    try:
        conn = get_auth_db()
        cur = conn.cursor()

        # Delete login record using user_id
        cur.execute(
            "UPDATE credentials SET is_active = FALSE WHERE user_id = %s;",
            (user_id,)
        )

        conn.commit()

        cur.close()
        conn.close()

        return jsonify({
            "message": "User login deleted successfully",
            "user_id": user_id
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# =====================================
# RUN
# =====================================
if __name__ == "__main__":
    app.run(debug=True)