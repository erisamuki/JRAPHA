const express = require('express');
const router = express.Router();

const { verifyToken, requireRole } = require('../../middleware/auth.middleware');
const {
  getPharmacyQueue, dispensePrescription,
  getStock, getStockAlerts, addStock, updateStock,
} = require('./pharmacy.controller');

router.use(verifyToken, requireRole('pharmacy', 'admin'));

router.get('/queue', getPharmacyQueue);
router.patch('/prescriptions/:id/dispense', dispensePrescription);

router.get('/stock', getStock);
router.get('/stock/alerts', getStockAlerts);
router.post('/stock', addStock);
router.patch('/stock/:id', updateStock);

module.exports = router;