from flask import Flask, jsonify
from flask_cors import CORS
from src.utils.db import get_conn

from src.routes.appointment_routes import doctor_bp
from src.routes.patient_qr_lookup import qr_bp

app = Flask(__name__)       
CORS(app, resources={r"/*": {"origins": ["http://localhost:5173"]}})

app.register_blueprint(doctor_bp, url_prefix="/api")
app.register_blueprint(qr_bp, url_prefix="/api")

@app.route("/")
def index():
    return jsonify({"status": "ok", "service": "nexuscare-backend"})

@app.route("/health")
def health():
    try:
        conn = get_conn()
        conn.close()
        return jsonify({"status": "OK", "message": "Database connected."})
    except Exception as e:
        return jsonify({"status": "ERROR", "message": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True)