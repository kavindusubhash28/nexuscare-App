-- Clinic & Scheduling Tables

CREATE SEQUENCE clinic_seq START 1 INCREMENT 1;

CREATE TABLE IF NOT EXISTS clinic (
  clinic_id VARCHAR(12) PRIMARY KEY,
  user_id VARCHAR(12) NOT NULL,
  clinic_location VARCHAR(150) NOT NULL,
  has_clinic_management BOOLEAN NOT NULL DEFAULT FALSE,

  CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Note: doctor_id removed to avoid circular dependency
-- Doctor-clinic relationship is managed through the availability table

CREATE SEQUENCE availability_seq START 1 INCREMENT 1;

CREATE TABLE IF NOT EXISTS availability (
  availability_id VARCHAR(12) PRIMARY KEY,
  doctor_id VARCHAR(12) NOT NULL,
  clinic_id VARCHAR(12) NOT NULL,
  available_date DATE NOT NULL,
  available_time TIME NOT NULL,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,

  CONSTRAINT fk_availability_doctor FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id) ON DELETE CASCADE,
  CONSTRAINT fk_availability_clinic FOREIGN KEY (clinic_id) REFERENCES clinic(clinic_id) ON DELETE CASCADE,
  CONSTRAINT uq_availability_slot UNIQUE (doctor_id, clinic_id, available_date, available_time)
);

CREATE SEQUENCE appointment_seq START 1 INCREMENT 1;

CREATE TABLE IF NOT EXISTS appointment (
  appointment_id VARCHAR(12) PRIMARY KEY,
  patient_id VARCHAR(12),
  doctor_id VARCHAR(12),
  clinic_id VARCHAR(12),
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'Waiting' CHECK (status IN ('Waiting', 'Ongoing', 'Conducted','Not Conducted')),
  is_paid BOOLEAN NOT NULL DEFAULT FALSE,

  CONSTRAINT fk_appointment_patient FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE,
  CONSTRAINT fk_appointment_doctor FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id) ON DELETE CASCADE,
  CONSTRAINT fk_appointment_clinic FOREIGN KEY (clinic_id) REFERENCES clinic(clinic_id) ON DELETE CASCADE
);

-- Performance Indexes for Fast Query Response (<2 seconds)
CREATE INDEX idx_appointment_date ON appointment(appointment_date);
CREATE INDEX idx_appointment_patient ON appointment(patient_id);
CREATE INDEX idx_appointment_doctor ON appointment(doctor_id);
CREATE INDEX idx_appointment_status ON appointment(status);
CREATE INDEX idx_availability_date ON availability(available_date);
CREATE INDEX idx_availability_doctor_clinic ON availability(doctor_id, clinic_id);