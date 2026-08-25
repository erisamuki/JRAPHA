const db = require('../../config/db');

// Generates a simple sequential patient number, e.g. JR-000123
async function generatePatientNumber() {
  const result = await db.query('SELECT COUNT(*) FROM patients');
  const nextNumber = parseInt(result.rows[0].count, 10) + 1;
  return `JR-${String(nextNumber).padStart(6, '0')}`;
}

// POST /api/reception/patients
async function registerPatient(req, res) {
  const {
    full_name, date_of_birth, gender, phone, nin,
    district, next_of_kin_name, next_of_kin_phone,
  } = req.body;

  if (!full_name) {
    return res.status(400).json({ error: 'full_name is required' });
  }

  try {
    const patient_number = await generatePatientNumber();

    const result = await db.query(
      `INSERT INTO patients
        (patient_number, full_name, date_of_birth, gender, phone, nin,
         district, next_of_kin_name, next_of_kin_phone, registered_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING *`,
      [patient_number, full_name, date_of_birth || null, gender || null,
        phone || null, nin || null, district || null,
        next_of_kin_name || null, next_of_kin_phone || null, req.user.id]
    );

    return res.status(201).json({ patient: result.rows[0] });
  } catch (err) {
    console.error('registerPatient error:', err);
    return res.status(500).json({ error: 'Failed to register patient' });
  }
}

// GET /api/reception/patients?search=name_or_phone_or_patient_number
async function searchPatients(req, res) {
  const { search } = req.query;

  try {
    let result;
    if (search) {
      result = await db.query(
        `SELECT * FROM patients
         WHERE full_name ILIKE $1 OR phone ILIKE $1 OR patient_number ILIKE $1
         ORDER BY created_at DESC LIMIT 50`,
        [`%${search}%`]
      );
    } else {
      result = await db.query(
        `SELECT * FROM patients ORDER BY created_at DESC LIMIT 50`
      );
    }
    return res.json({ patients: result.rows });
  } catch (err) {
    console.error('searchPatients error:', err);
    return res.status(500).json({ error: 'Failed to fetch patients' });
  }
}

// GET /api/reception/patients/:id
async function getPatient(req, res) {
  const { id } = req.params;
  try {
    const result = await db.query('SELECT * FROM patients WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }
    return res.json({ patient: result.rows[0] });
  } catch (err) {
    console.error('getPatient error:', err);
    return res.status(500).json({ error: 'Failed to fetch patient' });
  }
}

module.exports = { registerPatient, searchPatients, getPatient };