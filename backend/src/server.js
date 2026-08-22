require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const http = require('http');
const { Server } = require('socket.io');

const db = require('./config/db');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.set('io', io);

app.get('/api/health', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW()');
    res.json({ status: 'ok', db_time: result.rows[0].now });
  } catch (err) {
    console.error(err);
    res.status(500).json({ status: 'error', message: 'Database connection failed' });
  }
});

// ===== Route mounting (uncomment as each module is built) =====
// app.use('/api/auth', require('./modules/auth/auth.routes'));
// app.use('/api/admin', require('./modules/admin/admin.routes'));
app.use('/api/reception', require('./modules/reception/reception.routes'));
app.use('/api/nurse', require('./modules/nurse/nurse.routes'));
// app.use('/api/doctor', require('./modules/doctor/doctor.routes'));
// app.use('/api/laboratory', require('./modules/laboratory/laboratory.routes'));
// app.use('/api/pharmacy', require('./modules/pharmacy/pharmacy.routes'));
// app.use('/api/finance', require('./modules/finance/finance.routes'));
// app.use('/api/appointments', require('./modules/appointments/appointments.routes'));

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`JRapha backend running on port ${PORT}`);
});