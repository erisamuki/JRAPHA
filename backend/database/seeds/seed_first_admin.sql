-- ============================================================
-- Bootstrap the FIRST admin account
-- ============================================================
-- Every user created through the app's /register endpoint lands as
-- 'pending' and needs an admin to approve them. Since no admin exists
-- yet, the very first one must be inserted directly into the database.
--
-- STEP 1: Generate a bcrypt hash of your chosen admin password.
-- Run this in PowerShell from D:\Jrapha\backend (bcrypt is already
-- installed via npm install):
--
--   node -e "require('bcrypt').hash('YOUR_PASSWORD_HERE', 10).then(console.log)"
--
-- It will print a long hash starting with $2b$10$... — copy the WHOLE thing.
--
-- STEP 2: Paste that hash into the query below, replacing
-- PASTE_HASH_HERE. Also set your real name, email, and phone.
--
-- STEP 3: Run this file:
--   psql -h localhost -p 5432 -U postgres -d jrapha -f seed_first_admin.sql
-- ============================================================

INSERT INTO users (full_name, email, phone, password_hash, role, status, approved_at)
VALUES (
    'Mukisa Erisa',
    'erisamukisa51@gmail.com',
    '+256709997828',
    '$2b$10$.XLteYxqN4EvH4YEqvgLoOCLbngkmuVnL3zOkyeipiLkrxdP2Wh3a',
    'admin',
    'approved',
    now()
)
RETURNING id, full_name, email, role, status;