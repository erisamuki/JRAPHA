// src/config/db.js
const { PrismaClient } = require('../generated/prisma');
const { PrismaPg } = require('@prisma/adapter-pg');

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
});

const prisma = new PrismaClient({ adapter });

prisma.$connect()
  .then(() => {
    console.log('Connected to PostgreSQL (Neon via Prisma)');
  })
  .catch((err) => {
    console.error('Unexpected Prisma database connection error:', err);
    process.exit(1);
  });

module.exports = prisma;