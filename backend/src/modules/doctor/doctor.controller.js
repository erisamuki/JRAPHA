const db = require('../../config/db');

// GET /api/doctor/queue
// Visits that have been triaged (vitals done) and are waiting for a doctor
async function getDoctorQueue(req, res) {
  try {
    const result = await db.query(
      `SELECT v.id AS visit_id, v.visit_type, v.status, v.created_at,
              p.id AS patient_id, p.full_name, p.patient_number, p.date_of_birth, p.gender
       FROM visits v
       JOIN patients p ON p.id = v.patient_id
       WHERE v.status = 'triaged'
         AND (v.assigned_doctor IS NULL OR v.assigned_doctor = $1)
       ORDER BY v.created_at ASC`,
      [req.user.id]
    );
    return res.json({ queue: result.rows });
  } catch (err) {
    console.error('getDoctorQueue error:', err);
    return res.status(500).json({ error: 'Failed to fetch doctor queue' });
  }
}

// GET /api/doctor/visits/:visit_id
// Full record for one visit: patient info, latest vitals, past lab orders/prescriptions
async function getVisitDetail(req, res) {
  const { visit_id } = req.params;
  try {
    const visitResult = await db.query(
      `SELECT v.*, p.full_name, p.patient_number, p.date_of_birth, p.gender, p.phone
       FROM visits v JOIN patients p ON p.id = v.patient_id
       WHERE v.id = $1`,
      [visit_id]
    );
    if (visitResult.rows.length === 0) {
      return res.status(404).json({ error: 'Visit not found' });
    }

    const vitals = await db.query(
      `SELECT * FROM vitals WHERE visit_id = $1 ORDER BY recorded_at DESC`,
      [visit_id]
    );
    const labOrders = await db.query(
      `SELECT * FROM lab_orders WHERE visit_id = $1 ORDER BY ordered_at DESC`,
      [visit_id]
    );
    const prescriptions = await db.query(
      `SELECT * FROM prescriptions WHERE visit_id = $1 ORDER BY created_at DESC`,
      [visit_id]
    );

    return res.json({
      visit: visitResult.rows[0],
      vitals: vitals.rows,
      lab_orders: labOrders.rows,
      prescriptions: prescriptions.rows,
    });
  } catch (err) {
    console.error('getVisitDetail error:', err);
    return res.status(500).json({ error: 'Failed to fetch visit detail' });
  }
}

// POST /api/doctor/lab-orders
async function createLabOrder(req, res) {
  const { visit_id, test_name } = req.body;

  if (!visit_id || !test_name) {
    return res.status(400).json({ error: 'visit_id and test_name are required' });
  }

  try {
    const result = await db.query(
      `INSERT INTO lab_orders (visit_id, ordered_by, test_name, status)
       VALUES ($1,$2,$3,'ordered') RETURNING *`,
      [visit_id, req.user.id, test_name]
    );

    await db.query(`UPDATE visits SET status = 'lab_pending' WHERE id = $1`, [visit_id]);

    const io = req.app.get('io');
    io.emit('lab_order_created', result.rows[0]);

    return res.status(201).json({ lab_order: result.rows[0] });
  } catch (err) {
    console.error('createLabOrder error:', err);
    return res.status(500).json({ error: 'Failed to create lab order' });
  }
}

// POST /api/doctor/prescriptions
async function createPrescription(req, res) {
  const { visit_id, drug_name, dosage, duration, quantity } = req.body;

  if (!visit_id || !drug_name) {
    return res.status(400).json({ error: 'visit_id and drug_name are required' });
  }

  try {
    const result = await db.query(
      `INSERT INTO prescriptions (visit_id, doctor_id, drug_name, dosage, duration, quantity, status)
       VALUES ($1,$2,$3,$4,$5,$6,'pending') RETURNING *`,
      [visit_id, req.user.id, drug_name, dosage || null, duration || null, quantity || null]
    );

    await db.query(`UPDATE visits SET status = 'pharmacy_pending' WHERE id = $1`, [visit_id]);

    const io = req.app.get('io');
    io.emit('prescription_created', result.rows[0]);

    return res.status(201).json({ prescription: result.rows[0] });
  } catch (err) {
    console.error('createPrescription error:', err);
    return res.status(500).json({ error: 'Failed to create prescription' });
  }
}

module.exports = { getDoctorQueue, getVisitDetail, createLabOrder, createPrescription };