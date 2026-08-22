-- ============================================================
-- JRapha Hospital Management System — PostgreSQL Schema v0.1
-- ============================================================
-- Run against a fresh database, e.g.:
--   psql -U postgres -d jrapha -f schema.sql
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- ENUM TYPES
-- ============================================================

CREATE TYPE user_role AS ENUM (
    'admin', 'reception', 'nurse', 'doctor', 'laboratory', 'pharmacy'
);

CREATE TYPE user_status AS ENUM (
    'pending', 'approved', 'rejected', 'suspended'
);

CREATE TYPE visit_type AS ENUM ('opd', 'inpatient');

CREATE TYPE visit_status AS ENUM (
    'registered', 'triaged', 'with_doctor', 'lab_pending',
    'pharmacy_pending', 'admitted', 'discharged', 'closed'
);

CREATE TYPE lab_order_status AS ENUM (
    'ordered', 'sample_collected', 'in_progress', 'completed', 'cancelled'
);

CREATE TYPE prescription_status AS ENUM (
    'pending', 'dispensed', 'partially_dispensed', 'cancelled'
);

CREATE TYPE appointment_status AS ENUM (
    'scheduled', 'confirmed', 'completed', 'missed', 'cancelled'
);

CREATE TYPE payment_status AS ENUM (
    'unpaid', 'partially_paid', 'paid', 'waived'
);

CREATE TYPE payment_method AS ENUM (
    'cash', 'mtn_momo', 'airtel_money', 'insurance', 'other'
);

CREATE TYPE gender AS ENUM ('male', 'female', 'other');

-- ============================================================
-- USERS
-- ============================================================

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    phone           VARCHAR(20) UNIQUE,
    password_hash   TEXT NOT NULL,
    role            user_role NOT NULL,
    status          user_status NOT NULL DEFAULT 'pending',
    approved_by     UUID REFERENCES users(id),
    approved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);

-- ============================================================
-- PATIENTS
-- ============================================================

CREATE TABLE patients (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_number      VARCHAR(20) UNIQUE NOT NULL, -- facility-generated ID
    full_name           VARCHAR(150) NOT NULL,
    date_of_birth       DATE,
    gender              gender,
    phone               VARCHAR(20),
    nin                 VARCHAR(20),                  -- Uganda National ID
    district            VARCHAR(100),
    next_of_kin_name    VARCHAR(150),
    next_of_kin_phone   VARCHAR(20),
    registered_by       UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_patients_phone ON patients(phone);
CREATE INDEX idx_patients_name ON patients(full_name);

-- ============================================================
-- VISITS
-- ============================================================

CREATE TABLE visits (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    visit_type      visit_type NOT NULL,
    status          visit_status NOT NULL DEFAULT 'registered',
    ward            VARCHAR(50),        -- for inpatient
    bed_number      VARCHAR(20),        -- for inpatient
    assigned_doctor UUID REFERENCES users(id),
    created_by      UUID REFERENCES users(id), -- reception staff
    admitted_at     TIMESTAMPTZ,
    discharged_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_visits_patient ON visits(patient_id);
CREATE INDEX idx_visits_status ON visits(status);
CREATE INDEX idx_visits_type ON visits(visit_type);

-- ============================================================
-- VITALS
-- ============================================================

CREATE TABLE vitals (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id        UUID NOT NULL REFERENCES visits(id),
    recorded_by     UUID NOT NULL REFERENCES users(id), -- nurse
    blood_pressure  VARCHAR(15),   -- e.g. "120/80"
    temperature_c   NUMERIC(4,1),
    pulse_bpm       INTEGER,
    resp_rate       INTEGER,
    spo2_percent    INTEGER,
    weight_kg       NUMERIC(5,2),
    height_cm       NUMERIC(5,2),
    notes           TEXT,
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_vitals_visit ON vitals(visit_id);

-- ============================================================
-- LAB ORDERS
-- ============================================================

CREATE TABLE lab_orders (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id        UUID NOT NULL REFERENCES visits(id),
    ordered_by      UUID NOT NULL REFERENCES users(id), -- doctor
    test_name       VARCHAR(150) NOT NULL,
    status          lab_order_status NOT NULL DEFAULT 'ordered',
    result          TEXT,
    is_critical     BOOLEAN NOT NULL DEFAULT false,
    processed_by    UUID REFERENCES users(id), -- lab staff
    ordered_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ
);

CREATE INDEX idx_lab_orders_visit ON lab_orders(visit_id);
CREATE INDEX idx_lab_orders_status ON lab_orders(status);

-- ============================================================
-- PRESCRIPTIONS
-- ============================================================

CREATE TABLE prescriptions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id        UUID NOT NULL REFERENCES visits(id),
    doctor_id       UUID NOT NULL REFERENCES users(id),
    drug_name       VARCHAR(150) NOT NULL,
    dosage          VARCHAR(100),
    duration        VARCHAR(50),
    quantity        INTEGER,
    status          prescription_status NOT NULL DEFAULT 'pending',
    dispensed_by    UUID REFERENCES users(id), -- pharmacy staff
    dispensed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_prescriptions_visit ON prescriptions(visit_id);
CREATE INDEX idx_prescriptions_status ON prescriptions(status);

-- ============================================================
-- PHARMACY STOCK
-- ============================================================

CREATE TABLE pharmacy_stock (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    drug_name       VARCHAR(150) NOT NULL,
    batch_number    VARCHAR(50),
    quantity        INTEGER NOT NULL DEFAULT 0,
    unit            VARCHAR(20),          -- e.g. tablets, ml, vials
    reorder_level   INTEGER NOT NULL DEFAULT 10,
    expiry_date     DATE,
    unit_price_ugx  NUMERIC(12,2),
    updated_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_pharmacy_stock_name ON pharmacy_stock(drug_name);
CREATE INDEX idx_pharmacy_stock_expiry ON pharmacy_stock(expiry_date);

-- ============================================================
-- APPOINTMENTS
-- ============================================================

CREATE TABLE appointments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id      UUID NOT NULL REFERENCES patients(id),
    scheduled_with  UUID REFERENCES users(id), -- doctor, optional
    scheduled_at    TIMESTAMPTZ NOT NULL,
    status          appointment_status NOT NULL DEFAULT 'scheduled',
    reminder_sent   BOOLEAN NOT NULL DEFAULT false,
    created_by      UUID REFERENCES users(id), -- reception
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_scheduled_at ON appointments(scheduled_at);
CREATE INDEX idx_appointments_status ON appointments(status);

-- ============================================================
-- BILLING (FINANCE)
-- ============================================================

CREATE TABLE billing (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id        UUID NOT NULL REFERENCES visits(id),
    total_amount_ugx    NUMERIC(12,2) NOT NULL DEFAULT 0,
    amount_paid_ugx     NUMERIC(12,2) NOT NULL DEFAULT 0,
    payment_status  payment_status NOT NULL DEFAULT 'unpaid',
    payment_method  payment_method,
    processed_by    UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_billing_visit ON billing(visit_id);
CREATE INDEX idx_billing_status ON billing(payment_status);

CREATE TABLE billing_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    billing_id      UUID NOT NULL REFERENCES billing(id) ON DELETE CASCADE,
    description     VARCHAR(200) NOT NULL, -- e.g. "Consultation fee", "Malaria test"
    quantity        INTEGER NOT NULL DEFAULT 1,
    unit_price_ugx  NUMERIC(12,2) NOT NULL,
    total_price_ugx NUMERIC(12,2) NOT NULL
);

CREATE INDEX idx_billing_items_billing ON billing_items(billing_id);

-- ============================================================
-- NOTIFICATIONS (SMS LOG)
-- ============================================================

CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id      UUID REFERENCES patients(id),
    user_id         UUID REFERENCES users(id), -- for staff-directed alerts (e.g. critical lab result)
    type            VARCHAR(50) NOT NULL,      -- e.g. 'appointment_reminder', 'critical_lab_result'
    channel         VARCHAR(20) NOT NULL DEFAULT 'sms',
    message         TEXT NOT NULL,
    sent_at         TIMESTAMPTZ,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, sent, failed
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_patient ON notifications(patient_id);
CREATE INDEX idx_notifications_status ON notifications(status);

-- ============================================================
-- AUDIT LOG
-- ============================================================

CREATE TABLE audit_log (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID REFERENCES users(id),
    action          VARCHAR(100) NOT NULL,   -- e.g. 'user_approved', 'billing_edited'
    entity_type     VARCHAR(50) NOT NULL,    -- e.g. 'users', 'billing', 'visits'
    entity_id       UUID,
    details         JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_log_user ON audit_log(user_id);
CREATE INDEX idx_audit_log_entity ON audit_log(entity_type, entity_id);

-- ============================================================
-- UPDATED_AT TRIGGER (auto-update timestamp on row change)
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_patients_updated_at BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_visits_updated_at BEFORE UPDATE ON visits
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_pharmacy_stock_updated_at BEFORE UPDATE ON pharmacy_stock
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_billing_updated_at BEFORE UPDATE ON billing
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();