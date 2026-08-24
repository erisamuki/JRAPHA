const db = require('../../config/db');

// GET /api/admin/dashboard
// One call that aggregates everything the admin needs to see at a glance:
// OPD queue, in-patient list, pending user approvals, and today's finance summary.
async function getDashboard(req, res) {
  try {
    const [opd, inpatients, pendingUsers, todayRevenue, outstandingCount, lowStock] = await Promise.all([
      db.query(
        `SELECT v.id, v.status, v.created_at, p.full_name, p.patient_number
         FROM visits v JOIN patients p ON p.id = v.patient_id
         WHERE v.visit_type = 'opd' AND v.status NOT IN ('discharged', 'closed')
         ORDER BY v.created_at ASC`
      ),
      db.query(
        `SELECT v.id, v.status, v.ward, v.bed_number, v.admitted_at, p.full_name, p.patient_number
         FROM visits v JOIN patients p ON p.id = v.patient_id
         WHERE v.visit_type = 'inpatient' AND v.status NOT IN ('discharged', 'closed')
         ORDER BY v.admitted_at ASC`
      ),
      db.query(
        `SELECT id, full_name, email, role, created_at FROM users
         WHERE status = 'pending' ORDER BY created_at ASC`
      ),
      db.query(
        `SELECT COALESCE(SUM(amount_paid_ugx), 0) AS total
         FROM billing WHERE created_at::date = CURRENT_DATE`
      ),
      db.query(
        `SELECT COUNT(*) FROM billing WHERE payment_status IN ('unpaid', 'partially_paid')`
      ),
      db.query(
        `SELECT COUNT(*) FROM pharmacy_stock WHERE quantity <= reorder_level`
      ),
    ]);

    return res.json({
      opd_queue: opd.rows,
      inpatients: inpatients.rows,
      pending_users: pendingUsers.rows,
      today_revenue_ugx: todayRevenue.rows[0].total,
      outstanding_bills_count: parseInt(outstandingCount.rows[0].count, 10),
      low_stock_count: parseInt(lowStock.rows[0].count, 10),
    });
  } catch (err) {
    console.error('getDashboard error:', err);
    return res.status(500).json({ error: 'Failed to load admin dashboard' });
  }
}

// GET /api/admin/audit-log
async function getAuditLog(req, res) {
  try {
    const result = await db.query(
      `SELECT a.*, u.full_name AS acted_by
       FROM audit_log a
       LEFT JOIN users u ON u.id = a.user_id
       ORDER BY a.created_at DESC LIMIT 100`
    );
    return res.json({ audit_log: result.rows });
  } catch (err) {
    console.error('getAuditLog error:', err);
    return res.status(500).json({ error: 'Failed to fetch audit log' });
  }
}

// GET /api/admin/users
async function getAllUsers(req, res) {
  try {
    const result = await db.query(
      `SELECT id, full_name, email, phone, role, status, created_at, approved_at
       FROM users ORDER BY created_at DESC`
    );
    return res.json({ users: result.rows });
  } catch (err) {
    console.error('getAllUsers error:', err);
    return res.status(500).json({ error: 'Failed to fetch users' });
  }
}

module.exports = { getDashboard, getAuditLog, getAllUsers };