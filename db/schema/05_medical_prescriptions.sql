-- Medical records table (fixed: remove INT ids + missing doctor table)
CREATE TABLE IF NOT EXISTS medical_record (
  record_id BIGSERIAL PRIMARY KEY,
  patient_id VARCHAR(10) NOT NULL,
  doctor_id UUID NOT NULL,
  diagnosis TEXT NOT NULL,
  notes TEXT,
  visit_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_record_patient
    FOREIGN KEY (patient_id)
    REFERENCES patients(patient_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_record_doctor
    FOREIGN KEY (doctor_id)
    REFERENCES staff(user_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_medrec_patient ON medical_record(patient_id);
CREATE INDEX IF NOT EXISTS idx_medrec_doctor ON medical_record(doctor_id);

-- Prescriptions table (fixed: single correct version)
CREATE TABLE IF NOT EXISTS prescription (
  prescription_id BIGSERIAL PRIMARY KEY,
  record_id BIGINT NOT NULL,
  patient_id VARCHAR(10) NOT NULL,
  doctor_id UUID NOT NULL,
  medicine_name VARCHAR(100) NOT NULL,
  dosage VARCHAR(50) NOT NULL,
  frequency VARCHAR(50),
  duration_days INT CHECK (duration_days IS NULL OR duration_days > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_presc_record
    FOREIGN KEY (record_id)
    REFERENCES medical_record(record_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_presc_patient
    FOREIGN KEY (patient_id)
    REFERENCES patients(patient_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_presc_doctor
    FOREIGN KEY (doctor_id)
    REFERENCES staff(user_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_presc_record ON prescription(record_id);
CREATE INDEX IF NOT EXISTS idx_presc_patient ON prescription(patient_id);
CREATE INDEX IF NOT EXISTS idx_presc_doctor ON prescription(doctor_id);
