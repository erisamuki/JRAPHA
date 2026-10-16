const db = require('../../config/db');

// POST /api/finance/billing
// Creates a billing record for a visit with line items
async function createBilling(req, res) {
  const { visit_id, items } = req.body; // items: [{ description, quantity, unit_price_ugx }]

  if (!visit_id || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'visit_id and a non-empty items array are required' });
  }

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    const totalAmount = items.reduce(
      (sum, item) => sum + Number(item.quantity) * Number(item.unit_price_ugx), 0
    );

    const billingResult = await client.query(
      `INSERT INTO billing (visit_id, total_amount_ugx, payment_status, processed_by)
       VALUES ($1,$2,'unpaid',$3) RETURNING *`,
      [visit_id, totalAmount, req.user.id]
    );
    const billing = billingResult.rows[0];

    for (const item of items) {
      const totalPrice = Number(item.quantity) * Number(item.unit_price_ugx);
      await client.query(
        `INSERT INTO billing_items (billing_id, description, quantity, unit_price_ugx, total_price_ugx)
         VALUES ($1,$2,$3,$4,$5)`,
        [billing.id, item.description, item.quantity, item.unit_price_ugx, totalPrice]
      );
    }

    await client.query('COMMIT');

    const io = req.app.get('io');
    io.emit('billing_created', billing);

    return res.status(201).json({ billing });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('createBilling error:', err);
    return res.status(500).json({ error: 'Failed to create billing' });
  } finally {
    client.release();
  }
}

// GET /api/finance/billing/:id
async function getBilling(req, res) {
  const { id } = req.params;
  try {
    const billing = await db.query('SELECT * FROM billing WHERE id = $1', [id]);
    if (billing.rows.length === 0) {
      return res.status(404).json({ error: 'Billing record not found' });
    }
    const [items, payments] = await Promise.all([
      db.query('SELECT * FROM billing_items WHERE billing_id = $1 ORDER BY id', [id]),
      db.query('SELECT * FROM billing_payments WHERE billing_id = $1 ORDER BY created_at DESC', [id]),
    ]);
    return res.json({ billing: billing.rows[0], items: items.rows, payments: payments.rows });
  } catch (err) {
    console.error('getBilling error:', err);
    return res.status(500).json({ error: 'Failed to fetch billing' });
  }
}

// PATCH /api/finance/billing/:id/payment
// Records a payment against a billing record (full or partial)
async function recordPayment(req, res) {
  const { id } = req.params;
  const { amount_ugx, payment_method, reference } = req.body;
  const allowedMethods = ['cash', 'mtn_momo', 'airtel_money', 'bank_card', 'insurance', 'other'];
  const amount = Number(amount_ugx);

  if (!Number.isFinite(amount) || amount <= 0 || Math.abs(amount * 100 - Math.round(amount * 100)) > 1e-8) {
    return res.status(400).json({ error: 'amount_ugx must be a positive amount with at most two decimal places' });
  }
  if (!allowedMethods.includes(payment_method)) {
    return res.status(400).json({ error: `payment_method must be one of: ${allowedMethods.join(', ')}` });
  }
  if (reference != null && (typeof reference !== 'string' || reference.trim().length > 100)) {
    return res.status(400).json({ error: 'reference must be a string of at most 100 characters' });
  }

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    const billingResult = await client.query('SELECT * FROM billing WHERE id = $1 FOR UPDATE', [id]);
    if (billingResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Billing record not found' });
    }
    const billing = billingResult.rows[0];
    const amountPaid = Number(billing.amount_paid_ugx);
    const totalAmount = Number(billing.total_amount_ugx);
    const balanceDue = Math.round((totalAmount - amountPaid) * 100) / 100;

    if (amount > balanceDue) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Payment exceeds the outstanding balance', balance_due_ugx: balanceDue });
    }

    const newAmountPaid = Math.round((amountPaid + amount) * 100) / 100;
    const newStatus = newAmountPaid >= totalAmount ? 'paid' : 'partially_paid';
    await client.query(
      `INSERT INTO billing_payments (billing_id, amount_ugx, payment_method, reference, processed_by)
       VALUES ($1, $2, $3, $4, $5)`,
      [id, amount, payment_method, reference?.trim() || null, req.user.id]
    );
    const updated = await client.query(
      `UPDATE billing SET amount_paid_ugx = $1, payment_status = $2,
              payment_method = $3, processed_by = $4, updated_at = now()
       WHERE id = $5 RETURNING *`,
      [newAmountPaid, newStatus, payment_method, req.user.id, id]
    );
    await client.query('COMMIT');

    const io = req.app.get('io');
    if (io) io.emit('payment_recorded', updated.rows[0]);

    return res.json({ billing: updated.rows[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('recordPayment error:', err);
    return res.status(500).json({ error: 'Failed to record payment' });
  } finally {
    client.release();
  }
}

// GET /api/finance/outstanding
// All unpaid/partially-paid balances
async function getOutstandingBalances(req, res) {
  try {
    const result = await db.query(
      `SELECT b.*, (b.total_amount_ugx - b.amount_paid_ugx) AS balance_due_ugx,
              p.full_name, p.patient_number, v.visit_type
       FROM billing b
       JOIN visits v ON v.id = b.visit_id
       JOIN patients p ON p.id = v.patient_id
       WHERE b.payment_status IN ('unpaid', 'partially_paid')
       ORDER BY b.created_at DESC`
    );
    return res.json({ outstanding: result.rows });
  } catch (err) {
    console.error('getOutstandingBalances error:', err);
    return res.status(500).json({ error: 'Failed to fetch outstanding balances' });
  }
}

// GET /api/finance/revenue?period=daily|weekly|monthly
async function getRevenueReport(req, res) {
  const { period } = req.query;
  const bucket = { daily: 'day', weekly: 'week', monthly: 'month' }[period] || 'day';

  try {
    const result = await db.query(
      `SELECT date_trunc($1, created_at) AS period,
              SUM(amount_paid_ugx) AS total_collected,
              COUNT(*) AS billing_count
       FROM billing
       GROUP BY period
       ORDER BY period DESC
       LIMIT 30`,
      [bucket]
    );
    return res.json({ report: result.rows });
  } catch (err) {
    console.error('getRevenueReport error:', err);
    return res.status(500).json({ error: 'Failed to generate revenue report' });
  }
}

module.exports = {
  createBilling, getBilling, recordPayment, getOutstandingBalances, getRevenueReport,
};