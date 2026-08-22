const db = require('../../config/db');

// POST /api/reception/visits
// Creates a new OPD or in-patient visit for an existing patient.
async function createVisit(req, res) {
  const { patient_id, visit_type, ward, bed_number, assigned_doctor } = req.body;

  if (!patient_id || !visit_type) {
    return res.status(400).json({ error: 'patient_id and visit_type are required' });
  }
  if (!['opd', 'inpatient'].includes(visit_type)) {
    return res.status(400).json({ error: "visit_type must be 'opd' or 'inpatient'" });
  }

  try {
    const patientCheck = await db.query('SELECT id FROM patients WHERE id = $1', [patient_id]);
    if (patientCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }

    const result = await db.query(
      `INSERT INTO visits
        (patient_id, visit_type, ward, bed_number, assigned_doctor, created_by,
         admitted_at, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,'registered')
       RETURNING *`,
      [
        patient_id, visit_type, ward || null, bed_number || null,
        assigned_doctor || null, req.user.id,
        visit_type === 'inpatient' ? new Date() : null,
      ]
    );

    const visit = result.rows[0];

    // Push live update to admin/reception dashboards
    const io = req.app.get('io');
    io.emit('visit_created', visit);

    return res.status(201).json({ visit });
  } catch (err) {
    console.error('createVisit error:', err);
    return res.status(500).json({ error: 'Failed to create visit' });
  }
}

// GET /api/reception/visits/opd
// Live OPD dashboard — reception & admin
async function getOpdDashboard(req, res) {
  try {
    const result = await db.query(
      `SELECT v.id, v.status, v.created_at, v.assigned_doctor,
              p.id AS patient_id, p.full_name, p.patient_number, p.phone
       FROM visits v
       JOIN patients p ON p.id = v.patient_id
       WHERE v.visit_type = 'opd' AND v.status NOT IN ('discharged', 'closed')
       ORDER BY v.created_at ASC`
    );
    return res.json({ opd_queue: result.rows });
  } catch (err) {
    console.error('getOpdDashboard error:', err);
    return res.status(500).json({ error: 'Failed to fetch OPD dashboard' });
  }
}

// GET /api/reception/visits/inpatient
// Live in-patient dashboard — reception & admin
async function getInpatientDashboard(req, res) {
  try {
    const result = await db.query(
      `SELECT v.id, v.status, v.ward, v.bed_number, v.admitted_at, v.assigned_doctor,
              p.id AS patient_id, p.full_name, p.patient_number, p.phone
       FROM visits v
       JOIN patients p ON p.id = v.patient_id
       WHERE v.visit_type = 'inpatient' AND v.status NOT IN ('discharged', 'closed')
       ORDER BY v.admitted_at ASC`
    );
    return res.json({ inpatients: result.rows });
  } catch (err) {
    console.error('getInpatientDashboard error:', err);
    return res.status(500).json({ error: 'Failed to fetch in-patient dashboard' });
  }
}

// PATCH /api/reception/visits/:id/status
async function updateVisitStatus(req, res) {
  const { id } = req.params;
  const { status } = req.body;

  const validStatuses = [
    'registered', 'triaged', 'with_doctor', 'lab_pending',
    'pharmacy_pending', 'admitted', 'discharged', 'closed',
  ];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: `status must be one of: ${validStatuses.join(', ')}` });
  }

  try {
    const isDischarge = status === 'discharged';
    const result = await db.query(
      `UPDATE visits SET status = $1${isDischarge ? ', discharged_at = now()' : ''}
       WHERE id = $2 RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Visit not found' });
    }

    const io = req.app.get('io');
    io.emit('visit_status_changed', result.rows[0]);

    return res.json({ visit: result.rows[0] });
  } catch (err) {
    console.error('updateVisitStatus error:', err);
    return res.status(500).json({ error: 'Failed to update visit status' });
  }
}

module.exports = { createVisit, getOpdDashboard, getInpatientDashboard, updateVisitStatus };