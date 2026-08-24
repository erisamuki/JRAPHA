const express = require('express');
const router = express.Router();

const { verifyToken, requireRole } = require('../../middleware/auth.middleware');
const { getLabQueue, updateLabOrderStatus, submitResult } = require('./laboratory.controller');

router.use(verifyToken, requireRole('laboratory', 'admin'));

router.get('/queue', getLabQueue);
router.patch('/lab-orders/:id/status', updateLabOrderStatus);
router.patch('/lab-orders/:id/result', submitResult);

module.exports = router;