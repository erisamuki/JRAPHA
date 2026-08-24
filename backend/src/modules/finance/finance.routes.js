const express = require('express');
const router = express.Router();

const { verifyToken, requireRole } = require('../../middleware/auth.middleware');
const {
  createBilling, getBilling, recordPayment, getOutstandingBalances, getRevenueReport,
} = require('./finance.controller');

// Reception needs billing at point-of-service; admin needs full oversight
router.use(verifyToken, requireRole('reception', 'admin'));

router.post('/billing', createBilling);
router.get('/billing/:id', getBilling);
router.patch('/billing/:id/payment', recordPayment);
router.get('/outstanding', getOutstandingBalances);
router.get('/revenue', getRevenueReport);

module.exports = router;