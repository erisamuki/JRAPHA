const express = require('express');
const router = express.Router();

const { verifyToken, requireRole } = require('../../middleware/auth.middleware');
const {
  getDoctorQueue, getVisitDetail, createLabOrder, createPrescription,
} = require('./doctor.controller');

router.use(verifyToken, requireRole('doctor', 'admin'));

router.get('/queue', getDoctorQueue);
router.get('/visits/:visit_id', getVisitDetail);
router.post('/lab-orders', createLabOrder);
router.post('/prescriptions', createPrescription);

module.exports = router;