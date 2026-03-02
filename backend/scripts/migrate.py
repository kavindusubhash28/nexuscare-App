import os
from src.utils.db import get_conn

def create_tables():
    commands = [
        """
        CREATE TABLE IF NOT EXISTS doctors (
            id SERIAL PRIMARY KEY,
            firebase_uid VARCHAR(255) UNIQUE NOT NULL,
            full_name VARCHAR(255) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            specialization VARCHAR(255),
            hospital VARCHAR(255),
            license_number VARCHAR(100) UNIQUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS patient_qr_tokens (
            token VARCHAR(255) PRIMARY KEY,
            patient_id VARCHAR(100) NOT NULL,
            expires_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS access_grants (
            id SERIAL PRIMARY KEY,
            doctor_id INT REFERENCES doctors(id),
            patient_id VARCHAR(100) NOT NULL,
            access_type VARCHAR(50) DEFAULT 'temporary', -- 'temporary', 'permanent'
            status VARCHAR(50) DEFAULT 'active', -- 'active', 'revoked', 'expired'
            expires_at TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(doctor_id, patient_id)
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS consultations (
            id SERIAL PRIMARY KEY,
            doctor_id INT REFERENCES doctors(id),
            patient_id VARCHAR(100) NOT NULL,
            start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            end_time TIMESTAMP,
            notes TEXT,
            status VARCHAR(50) DEFAULT 'ongoing' -- 'ongoing', 'completed', 'cancelled'
        )
        """
    ]
    
    conn = None
    try:
        conn = get_conn()
        cur = conn.cursor()
        for command in commands:
            cur.execute(command)
        conn.commit()
        cur.close()
        print("Tables created successfully.")
    except Exception as e:
        print(f"Error creating tables: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    create_tables()
