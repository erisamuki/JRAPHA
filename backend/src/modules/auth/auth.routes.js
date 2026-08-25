const express = require('express');
const router = express.Router();

const { register, login, getPendingUsers, approveUser, rejectUser } = require('./auth.controller');
const { verifyToken, requireRole } = require('../../middleware/auth.middleware');

// Public
router.post('/register', register);
router.post('/login', login);

// Admin only
router.get('/pending-users', verifyToken, requireRole('admin'), getPendingUsers);
router.patch('/users/:id/approve', verifyToken, requireRole('admin'), approveUser);
router.patch('/users/:id/reject', verifyToken, requireRole('admin'), rejectUser);

module.exports = router;