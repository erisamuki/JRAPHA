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
    const existing = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'A user with this email already exists' });
    }

    const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

    const result = await db.query(
      `INSERT INTO users (full_name, email, phone, password_hash, role, status)
       VALUES ($1, $2, $3, $4, $5, 'pending')
       RETURNING id, full_name, email, role, status, created_at`,
      [full_name, email, phone || null, password_hash, role]
    );

    const newUser = result.rows[0];

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
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = result.rows[0];

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
    const result = await db.query(
      `SELECT id, full_name, email, phone, role, created_at
       FROM users WHERE status = 'pending' ORDER BY created_at ASC`
    );
    return res.json({ users: result.rows });
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
    const result = await db.query(
      `UPDATE users SET status = 'approved', approved_by = $1, approved_at = now()
       WHERE id = $2 RETURNING id, full_name, email, role, status`,
      [adminId, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    await db.query(
      `INSERT INTO audit_log (user_id, action, entity_type, entity_id, details)
       VALUES ($1, 'user_approved', 'users', $2, $3)`,
      [adminId, id, JSON.stringify({ approved_user_email: result.rows[0].email })]
    );

    // Notify connected admin dashboards in real time
    const io = req.app.get('io');
    io.emit('user_status_changed', result.rows[0]);

    return res.json({ message: 'User approved', user: result.rows[0] });
  } catch (err) {
    console.error('approveUser error:', err);
    return res.status(500).json({ error: 'Failed to approve user' });
  }
}

// PATCH /api/auth/users/:id/reject  (admin only)
async function rejectUser(req, res) {
  const { id } = req.params;
  const adminId = req.user.id;

  try {
    const result = await db.query(
      `UPDATE users SET status = 'rejected', approved_by = $1, approved_at = now()
       WHERE id = $2 RETURNING id, full_name, email, role, status`,
      [adminId, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    await db.query(
      `INSERT INTO audit_log (user_id, action, entity_type, entity_id, details)
       VALUES ($1, 'user_rejected', 'users', $2, $3)`,
      [adminId, id, JSON.stringify({ rejected_user_email: result.rows[0].email })]
    );

    const io = req.app.get('io');
    io.emit('user_status_changed', result.rows[0]);

    return res.json({ message: 'User rejected', user: result.rows[0] });
  } catch (err) {
    console.error('rejectUser error:', err);
    return res.status(500).json({ error: 'Failed to reject user' });
  }
}

module.exports = { register, login, getPendingUsers, approveUser, rejectUser };