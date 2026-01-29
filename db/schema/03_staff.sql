CREATE TABLE IF NOT EXISTS staff (
  user_id UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE, 
  registration_no VARCHAR(50) NOT NULL UNIQUE,
  organization VARCHAR(120) NOT NULL,
  specialization VARCHAR(100), 
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_staff_organization ON staff (organization);
CREATE INDEX IF NOT EXISTS idx_staff_reg_no ON staff (registration_no); 
