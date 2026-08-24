const db = require('../../config/db');

// GET /api/pharmacy/queue
// Prescriptions waiting to be dispensed
async function getPharmacyQueue(req, res) {
  try {
    const result = await db.query(
      `SELECT pr.*, p.full_name, p.patient_number
       FROM prescriptions pr
       JOIN visits v ON v.id = pr.visit_id
       JOIN patients p ON p.id = v.patient_id
       WHERE pr.status IN ('pending', 'partially_dispensed')
       ORDER BY pr.created_at ASC`
    );
    return res.json({ queue: result.rows });
  } catch (err) {
    console.error('getPharmacyQueue error:', err);
    return res.status(500).json({ error: 'Failed to fetch pharmacy queue' });
  }
}

// PATCH /api/pharmacy/prescriptions/:id/dispense
// Marks a prescription dispensed (or partially) and decrements stock if a
// matching drug_name entry exists in pharmacy_stock.
async function dispensePrescription(req, res) {
  const { id } = req.params;
  const { status } = req.body; // 'dispensed' or 'partially_dispensed'

  if (!['dispensed', 'partially_dispensed'].includes(status)) {
    return res.status(400).json({ error: "status must be 'dispensed' or 'partially_dispensed'" });
  }

  try {
    const prescriptionResult = await db.query('SELECT * FROM prescriptions WHERE id = $1', [id]);
    if (prescriptionResult.rows.length === 0) {
      return res.status(404).json({ error: 'Prescription not found' });
    }
    const prescription = prescriptionResult.rows[0];

    const updated = await db.query(
      `UPDATE prescriptions SET status = $1, dispensed_by = $2, dispensed_at = now()
       WHERE id = $3 RETURNING *`,
      [status, req.user.id, id]
    );

    // Best-effort stock decrement if a matching drug exists
    if (prescription.quantity) {
      await db.query(
        `UPDATE pharmacy_stock SET quantity = GREATEST(quantity - $1, 0), updated_by = $2
         WHERE drug_name = $3`,
        [prescription.quantity, req.user.id, prescription.drug_name]
      );
    }

    // If all prescriptions for this visit are dispensed, close out that stage
    const remaining = await db.query(
      `SELECT COUNT(*) FROM prescriptions WHERE visit_id = $1 AND status = 'pending'`,
      [prescription.visit_id]
    );
    if (parseInt(remaining.rows[0].count, 10) === 0) {
      await db.query(`UPDATE visits SET status = 'closed' WHERE id = $1`, [prescription.visit_id]);
    }

    const io = req.app.get('io');
    io.emit('prescription_dispensed', updated.rows[0]);

    return res.json({ prescription: updated.rows[0] });
  } catch (err) {
    console.error('dispensePrescription error:', err);
    return res.status(500).json({ error: 'Failed to dispense prescription' });
  }
}

// ===== Stock management =====

// GET /api/pharmacy/stock
async function getStock(req, res) {
  try {
    const result = await db.query(`SELECT * FROM pharmacy_stock ORDER BY drug_name ASC`);
    return res.json({ stock: result.rows });
  } catch (err) {
    console.error('getStock error:', err);
    return res.status(500).json({ error: 'Failed to fetch stock' });
  }
}

// GET /api/pharmacy/stock/alerts
// Low-stock (below reorder_level) and near-expiry (within 90 days) items
async function getStockAlerts(req, res) {
  try {
    const lowStock = await db.query(
      `SELECT * FROM pharmacy_stock WHERE quantity <= reorder_level ORDER BY quantity ASC`
    );
    const nearExpiry = await db.query(
      `SELECT * FROM pharmacy_stock
       WHERE expiry_date IS NOT NULL AND expiry_date <= (CURRENT_DATE + INTERVAL '90 days')
       ORDER BY expiry_date ASC`
    );
    return res.json({ low_stock: lowStock.rows, near_expiry: nearExpiry.rows });
  } catch (err) {
    console.error('getStockAlerts error:', err);
    return res.status(500).json({ error: 'Failed to fetch stock alerts' });
  }
}

// POST /api/pharmacy/stock
async function addStock(req, res) {
  const { drug_name, batch_number, quantity, unit, reorder_level, expiry_date, unit_price_ugx } = req.body;

  if (!drug_name || quantity === undefined) {
    return res.status(400).json({ error: 'drug_name and quantity are required' });
  }

  try {
    const result = await db.query(
      `INSERT INTO pharmacy_stock
        (drug_name, batch_number, quantity, unit, reorder_level, expiry_date, unit_price_ugx, updated_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [drug_name, batch_number || null, quantity, unit || null,
        reorder_level || 10, expiry_date || null, unit_price_ugx || null, req.user.id]
    );

    const stockItem = result.rows[0];
    if (stockItem.quantity <= stockItem.reorder_level) {
      const io = req.app.get('io');
      io.emit('low_stock_alert', stockItem);
    }

    return res.status(201).json({ stock_item: stockItem });
  } catch (err) {
    console.error('addStock error:', err);
    return res.status(500).json({ error: 'Failed to add stock' });
  }
}

// PATCH /api/pharmacy/stock/:id
async function updateStock(req, res) {
  const { id } = req.params;
  const { quantity, reorder_level, expiry_date, unit_price_ugx } = req.body;

  try {
    const result = await db.query(
      `UPDATE pharmacy_stock SET
         quantity = COALESCE($1, quantity),
         reorder_level = COALESCE($2, reorder_level),
         expiry_date = COALESCE($3, expiry_date),
         unit_price_ugx = COALESCE($4, unit_price_ugx),
         updated_by = $5
       WHERE id = $6 RETURNING *`,
      [quantity, reorder_level, expiry_date, unit_price_ugx, req.user.id, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Stock item not found' });
    }

    const stockItem = result.rows[0];
    if (stockItem.quantity <= stockItem.reorder_level) {
      const io = req.app.get('io');
      io.emit('low_stock_alert', stockItem);
    }

    return res.json({ stock_item: stockItem });
  } catch (err) {
    console.error('updateStock error:', err);
    return res.status(500).json({ error: 'Failed to update stock' });
  }
}

module.exports = {
  getPharmacyQueue, dispensePrescription,
  getStock, getStockAlerts, addStock, updateStock,
};