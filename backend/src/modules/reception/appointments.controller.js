const db = require('../../config/db');

// POST /api/reception/appointments
async function createAppointment(req, res) {
  const { patient_id, scheduled_with, scheduled_at, notes } = req.body;

  if (!patient_id || !scheduled_at) {
    return res.status(400).json({ error: 'patient_id and scheduled_at are required' });
  }

  try {
    const result = await db.query(
      `INSERT INTO appointments (patient_id, scheduled_with, scheduled_at, notes, created_by)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [patient_id, scheduled_with || null, scheduled_at, notes || null, req.user.id]
    );
    return res.status(201).json({ appointment: result.rows[0] });
  } catch (err) {
    console.error('createAppointment error:', err);
    return res.status(500).json({ error: 'Failed to create appointment' });
  }
}

// GET /api/reception/appointments?date=YYYY-MM-DD
// Reception's appointment calendar view
async function getAppointments(req, res) {
  const { date } = req.query;

  try {
    let result;
    if (date) {
      result = await db.query(
        `SELECT a.*, p.full_name, p.phone, p.patient_number
         FROM appointments a
         JOIN patients p ON p.id = a.patient_id
         WHERE a.scheduled_at::date = $1
         ORDER BY a.scheduled_at ASC`,
        [date]
      );
    } else {
      result = await db.query(
        `SELECT a.*, p.full_name, p.phone, p.patient_number
         FROM appointments a
         JOIN patients p ON p.id = a.patient_id
         WHERE a.scheduled_at >= now()
         ORDER BY a.scheduled_at ASC LIMIT 100`
      );
    }
    return res.json({ appointments: result.rows });
  } catch (err) {
    console.error('getAppointments error:', err);
    return res.status(500).json({ error: 'Failed to fetch appointments' });
  }
}

module.exports = { createAppointment, getAppointments };