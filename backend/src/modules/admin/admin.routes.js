const express = require('express');
const router = express.Router();

const { verifyToken, requireRole } = require('../../middleware/auth.middleware');
const { getDashboard, getAuditLog, getAllUsers } = require('./admin.controller');

router.use(verifyToken, requireRole('admin'));

router.get('/dashboard', getDashboard);
router.get('/audit-log', getAuditLog);
router.get('/users', getAllUsers);

module.exports = router;