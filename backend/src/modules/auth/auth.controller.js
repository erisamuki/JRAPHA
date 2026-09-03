const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');
const { notifyAdminsOfNewRegistration } = require('../notifications/email.service');

const SALT_ROUNDS = 10;

// POST /api/auth/register
// Anyone can register, but account sits as 'pending' until an admin approves it.
async function register(req, res) {
  const { full_name, email, phone, password, role } = req.body;

  if (!full_name || !email || !password || !role) {
    return res.status(400).json({ error: 'full_name, email, password, and role are required' });
  }

  const validRoles = ['admin', 'reception', 'nurse', 'doctor', 'laboratory', 'pharmacy'];
  if (!validRoles.includes(role)) {
    return res.status(400).json({ error: `role must be one of: ${validRoles.join(', ')}` });
  }

  try {
    const existing = await db.users.findUnique({ where: { email } });
    if (existing) {
      return res.status(409).json({ error: 'A user with this email already exists' });
    }

    const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

    const newUser = await db.users.create({
      data: {
        full_name,
        email,
        phone: phone || null,
        password_hash,
        role,
        status: 'pending',
      },
      select: {
        id: true,
        full_name: true,
        email: true,
        role: true,
        status: true,
        created_at: true,
      },
    });

    // Fire-and-forget: don't block the response on email delivery
    notifyAdminsOfNewRegistration(newUser, db);

    return res.status(201).json({
      message: 'Registration submitted. Your account is pending admin approval.',
      user: newUser,
    });
  } catch (err) {
    console.error('register error:', err);
    return res.status(500).json({ error: 'Registration failed' });
  }
}

// POST /api/auth/login
async function login(req, res) {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required' });
  }

  try {
    const user = await db.users.findUnique({ where: { email } });

    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const passwordMatches = await bcrypt.compare(password, user.password_hash);
    if (!passwordMatches) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    if (user.status === 'pending') {
      return res.status(403).json({ error: 'Your account is still pending admin approval' });
    }
    if (user.status === 'rejected') {
      return res.status(403).json({ error: 'Your account request was rejected' });
    }
    if (user.status === 'suspended') {
      return res.status(403).json({ error: 'Your account has been suspended' });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    return res.json({
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
        status: user.status,
      },
    });
  } catch (err) {
    console.error('login error:', err);
    return res.status(500).json({ error: 'Login failed' });
  }
}

// GET /api/auth/pending-users  (admin only)
async function getPendingUsers(req, res) {
  try {
    const users = await db.users.findMany({
      where: { status: 'pending' },
      select: {
        id: true,
        full_name: true,
        email: true,
        phone: true,
        role: true,
        created_at: true,
      },
      orderBy: { created_at: 'asc' },
    });
    return res.json({ users });
  } catch (err) {
    console.error('getPendingUsers error:', err);
    return res.status(500).json({ error: 'Failed to fetch pending users' });
  }
}

// PATCH /api/auth/users/:id/approve  (admin only)
async function approveUser(req, res) {
  const { id } = req.params;
  const adminId = req.user.id;

  try {
    const updatedUser = await db.users.update({
      where: { id },
      data: {
        status: 'approved',
        approved_by: adminId,
        approved_at: new Date(),
      },
      select: {
        id: true,
        full_name: true,
        email: true,
        role: true,
        status: true,
      },
    });

    await db.audit_log.create({
      data: {
        user_id: adminId,
        action: 'user_approved',
        entity_type: 'users',
        entity_id: id,
        details: { approved_user_email: updatedUser.email },
      },
    });

    // Notify connected admin dashboards in real time
    const io = req.app.get('io');
    io.emit('user_status_changed', updatedUser);

    return res.json({ message: 'User approved', user: updatedUser });
  } catch (err) {
    if (err.code === 'P2025') {
      return res.status(404).json({ error: 'User not found' });
    }
    console.error('approveUser error:', err);
    return res.status(500).json({ error: 'Failed to approve user' });
  }
}

// PATCH /api/auth/users/:id/reject  (admin only)
async function rejectUser(req, res) {
  const { id } = req.params;
  const adminId = req.user.id;

  try {
    const updatedUser = await db.users.update({
      where: { id },
      data: {
        status: 'rejected',
        approved_by: adminId,
        approved_at: new Date(),
      },
      select: {
        id: true,
        full_name: true,
        email: true,
        role: true,
        status: true,
      },
    });

    await db.audit_log.create({
      data: {
        user_id: adminId,
        action: 'user_rejected',
        entity_type: 'users',
        entity_id: id,
        details: { rejected_user_email: updatedUser.email },
      },
    });

    const io = req.app.get('io');
    io.emit('user_status_changed', updatedUser);

    return res.json({ message: 'User rejected', user: updatedUser });
  } catch (err) {
    if (err.code === 'P2025') {
      return res.status(404).json({ error: 'User not found' });
    }
    console.error('rejectUser error:', err);
    return res.status(500).json({ error: 'Failed to reject user' });
  }
}

module.exports = { register, login, getPendingUsers, approveUser, rejectUser };