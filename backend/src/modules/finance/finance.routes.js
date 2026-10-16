const express = require('express');
const router = express.Router();

const { verifyToken, requireRole } = require('../../middleware/auth.middleware');
const {
  createBilling, getBilling, recordPayment, getOutstandingBalances, getRevenueReport,
} = require('./finance.controller');

router.use(verifyToken);

router.post('/billing', requireRole('reception', 'admin'), createBilling);
router.get('/billing/:id', requireRole('cashier', 'reception', 'admin'), getBilling);
router.patch('/billing/:id/payment', requireRole('cashier', 'reception', 'admin'), recordPayment);
router.get('/outstanding', requireRole('cashier', 'reception', 'admin'), getOutstandingBalances);
router.get('/revenue', requireRole('cashier', 'reception', 'admin'), getRevenueReport);

module.exports = router;