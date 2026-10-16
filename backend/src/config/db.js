// src/config/db.js
const { PrismaClient } = require('../generated/prisma');
const { PrismaPg } = require('@prisma/adapter-pg');
const { Pool } = require('pg');

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
});

const prisma = new PrismaClient({ adapter });
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

pool.on('error', (err) => {
  console.error('Unexpected PostgreSQL pool error:', err);
});

const db = {
  pool,
  query: (text, values) => pool.query(text, values),
  users: prisma.users,
  audit_log: prisma.audit_log,
};

Promise.all([pool.query('SELECT 1'), prisma.$connect()])
  .then(() => {
    console.log('Connected to PostgreSQL database');
  })
  .catch((err) => {
    console.error('Unexpected database connection error:', err);
    process.exit(1);
  });

module.exports = db;