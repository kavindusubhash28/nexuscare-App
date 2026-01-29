-- 1) Orders Table (Pharmacy)
CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    patient_id VARCHAR(10) NOT NULL, 
    prescription_id INT,             
    total_price NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT fk_order_patient 
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_prescription 
        FOREIGN KEY (prescription_id) REFERENCES prescription(prescription_id) ON DELETE SET NULL
);

-- 2) Priority Orders (Inheritance from Orders)
CREATE TABLE IF NOT EXISTS priority_orders (
    order_id INT PRIMARY KEY,
    collecting_time INTERVAL,
    additional_charge NUMERIC(10,2),

    CONSTRAINT fk_priority_order 
        FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- 3) Normal Orders (Inheritance from Orders)
CREATE TABLE IF NOT EXISTS normal_orders (
    order_id INT PRIMARY KEY,
    is_prepared BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_normal_order 
        FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- 4) Recommended Reports (Doctor requesting a lab test)
CREATE TABLE IF NOT EXISTS recommended_reports (
    report_id SERIAL PRIMARY KEY,
    patient_id VARCHAR(10) NOT NULL, 
    doctor_id UUID NOT NULL,        
    test_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT fk_recommended_patient 
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    CONSTRAINT fk_recommended_doctor 
        FOREIGN KEY (doctor_id) REFERENCES staff(user_id) ON DELETE CASCADE
);

-- 5) Lab Reports (Actual results uploaded by Lab staff)
CREATE TABLE IF NOT EXISTS lab_reports (
    lab_report_id SERIAL PRIMARY KEY,
    patient_id VARCHAR(10) NOT NULL, 
    doctor_id UUID NOT NULL,        
    lab_id UUID NOT NULL,           
    test_name VARCHAR(100) NOT NULL,
    file_url TEXT NOT NULL,         
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT fk_lab_patient 
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    CONSTRAINT fk_lab_doctor 
        FOREIGN KEY (doctor_id) REFERENCES staff(user_id),
    CONSTRAINT fk_lab_staff 
        FOREIGN KEY (lab_id) REFERENCES staff(user_id)
);
