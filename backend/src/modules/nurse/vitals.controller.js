const db = require('../../config/db');

// GET /api/nurse/queue
// Patients currently waiting for triage/vitals (OPD registered, not yet triaged)
async function getNurseQueue(req, res) {
  try {
    const result = await db.query(
      `SELECT v.id AS visit_id, v.visit_type, v.status, v.created_at,
              p.id AS patient_id, p.full_name, p.patient_number, p.date_of_birth, p.gender
       FROM visits v
       JOIN patients p ON p.id = v.patient_id
       WHERE v.status IN ('registered', 'admitted')
       ORDER BY v.created_at ASC`
    );
    return res.json({ queue: result.rows });
  } catch (err) {
    console.error('getNurseQueue error:', err);
    return res.status(500).json({ error: 'Failed to fetch nurse queue' });
  }
}

// POST /api/nurse/vitals
// Records vitals for a visit and advances the visit to 'triaged'
async function recordVitals(req, res) {
  const {
    visit_id, blood_pressure, temperature_c, pulse_bpm,
    resp_rate, spo2_percent, weight_kg, height_cm, notes,
  } = req.body;

  if (!visit_id) {
    return res.status(400).json({ error: 'visit_id is required' });
  }

  try {
    const visitCheck = await db.query('SELECT id, status FROM visits WHERE id = $1', [visit_id]);
    if (visitCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Visit not found' });
    }

    const result = await db.query(
      `INSERT INTO vitals
        (visit_id, recorded_by, blood_pressure, temperature_c, pulse_bpm,
         resp_rate, spo2_percent, weight_kg, height_cm, notes)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING *`,
      [
        visit_id, req.user.id, blood_pressure || null, temperature_c || null,
        pulse_bpm || null, resp_rate || null, spo2_percent || null,
        weight_kg || null, height_cm || null, notes || null,
      ]
    );

    // Move the visit forward so it shows up in the doctor's queue next
    const updatedVisit = await db.query(
      `UPDATE visits SET status = 'triaged' WHERE id = $1 RETURNING *`,
      [visit_id]
    );

    const io = req.app.get('io');
    io.emit('visit_status_changed', updatedVisit.rows[0]);
    io.emit('vitals_recorded', result.rows[0]);

    return res.status(201).json({ vitals: result.rows[0], visit: updatedVisit.rows[0] });
  } catch (err) {
    console.error('recordVitals error:', err);
    return res.status(500).json({ error: 'Failed to record vitals' });
  }
}

// GET /api/nurse/vitals/:visit_id
// Vitals history for a specific visit
async function getVitalsForVisit(req, res) {
  const { visit_id } = req.params;
  try {
    const result = await db.query(
      `SELECT vi.*, u.full_name AS recorded_by_name
       FROM vitals vi
       JOIN users u ON u.id = vi.recorded_by
       WHERE vi.visit_id = $1
       ORDER BY vi.recorded_at DESC`,
      [visit_id]
    );
    return res.json({ vitals: result.rows });
  } catch (err) {
    console.error('getVitalsForVisit error:', err);
    return res.status(500).json({ error: 'Failed to fetch vitals' });
  }
}

module.exports = { getNurseQueue, recordVitals, getVitalsForVisit };