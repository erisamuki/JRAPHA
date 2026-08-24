const db = require('../../config/db');

// GET /api/laboratory/queue
// Lab orders waiting to be processed
async function getLabQueue(req, res) {
  try {
    const result = await db.query(
      `SELECT lo.*, p.full_name, p.patient_number, v.visit_type
       FROM lab_orders lo
       JOIN visits v ON v.id = lo.visit_id
       JOIN patients p ON p.id = v.patient_id
       WHERE lo.status IN ('ordered', 'sample_collected', 'in_progress')
       ORDER BY lo.ordered_at ASC`
    );
    return res.json({ queue: result.rows });
  } catch (err) {
    console.error('getLabQueue error:', err);
    return res.status(500).json({ error: 'Failed to fetch lab queue' });
  }
}

// PATCH /api/laboratory/lab-orders/:id/status
// Moves an order through sample_collected -> in_progress -> completed/cancelled
async function updateLabOrderStatus(req, res) {
  const { id } = req.params;
  const { status } = req.body;

  const validStatuses = ['sample_collected', 'in_progress', 'completed', 'cancelled'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: `status must be one of: ${validStatuses.join(', ')}` });
  }

  try {
    const result = await db.query(
      `UPDATE lab_orders SET status = $1, processed_by = $2
       ${status === 'completed' ? ', completed_at = now()' : ''}
       WHERE id = $3 RETURNING *`,
      [status, req.user.id, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Lab order not found' });
    }

    const io = req.app.get('io');
    io.emit('lab_order_status_changed', result.rows[0]);

    return res.json({ lab_order: result.rows[0] });
  } catch (err) {
    console.error('updateLabOrderStatus error:', err);
    return res.status(500).json({ error: 'Failed to update lab order status' });
  }
}

// PATCH /api/laboratory/lab-orders/:id/result
// Records the result, marks completed, optionally flags as critical, and
// advances the visit back so the doctor sees it's ready.
async function submitResult(req, res) {
  const { id } = req.params;
  const { result: labResult, is_critical } = req.body;

  if (!labResult) {
    return res.status(400).json({ error: 'result is required' });
  }

  try {
    const orderResult = await db.query(
      `UPDATE lab_orders
       SET result = $1, is_critical = $2, status = 'completed',
           processed_by = $3, completed_at = now()
       WHERE id = $4 RETURNING *`,
      [labResult, !!is_critical, req.user.id, id]
    );

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Lab order not found' });
    }

    const labOrder = orderResult.rows[0];

    // Move the visit back to with_doctor so it reappears in the doctor's active list
    await db.query(
      `UPDATE visits SET status = 'with_doctor' WHERE id = $1`,
      [labOrder.visit_id]
    );

    const io = req.app.get('io');
    io.emit('lab_result_ready', labOrder);

    if (labOrder.is_critical) {
      // Notify the ordering doctor specifically about the critical result
      const doctor = await db.query('SELECT id FROM users WHERE id = $1', [labOrder.ordered_by]);
      if (doctor.rows.length > 0) {
        await db.query(
          `INSERT INTO notifications (user_id, type, channel, message, status)
           VALUES ($1, 'critical_lab_result', 'in_app', $2, 'pending')`,
          [labOrder.ordered_by, `Critical result ready for lab order: ${labOrder.test_name}`]
        );
      }
      io.emit('critical_lab_result', labOrder);
    }

    return res.json({ lab_order: labOrder });
  } catch (err) {
    console.error('submitResult error:', err);
    return res.status(500).json({ error: 'Failed to submit lab result' });
  }
}

module.exports = { getLabQueue, updateLabOrderStatus, submitResult };