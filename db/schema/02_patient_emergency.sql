--Create sequence for patients numbers
CREATE SEQUENCE patient_seq
START 1
INCREMENT 1;

--Create patients table
CREATE TABLE IF NOT EXISTS patients (
    patient_id VARCHAR(10) PRIMARY KEY,
    user_id UUID UNIQUE NOT NULL,
    nic VARCHAR(20) UNIQUE NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10),
    image_url VARCHAR(2048),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_patient_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

--Create trigger function
CREATE OR REPLACE FUNCTION generate_patient_id()
RETURns TRIGGER As $$
BEGIN
    NEW.patient_id :=
        'PT' || LpaD(nextval('patient_seq')::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGuaGE plpgsql;

--Create trigger
CREATE TRIGGER trg_generate_patient_id
BEFORE INSERT ON patients FOR EACH ROW
EXECUTE Function generate_patient_id();

-- Create emergency_profile table
CREATE TABLE IF NOT EXISTS emergency_profile (
    patient_id VARCHAR(10) PRIMARY KEY,
    contact_name VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    chornical_conditions TEXT,
    blood_group VARCHAR(5),
    allergies TEXT,
    is_public_visible BOOLEAN,

    CONSTRAINT fk_emergency_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON DELETE CASCADE
);
