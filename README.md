# JRapha - Hospital Management System

A comprehensive, scalable hospital management system built with modern web technologies. JRapha provides integrated solutions for patient management, appointments, billing, and clinical operations.

**Status:** In Development | **Version:** 0.1.0

---

## 📋 Table of Contents

- [Overview](#overview)
- [Technology Stack](#technology-stack)
- [System Architecture](#system-architecture)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [Database Management](#database-management)
- [API Documentation](#api-documentation)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

---

## 📱 Overview

JRapha is a full-featured Hospital Management System designed to streamline hospital operations and improve patient care delivery. The platform integrates critical healthcare functions including:

- **Patient Management** - Complete patient records and medical history
- **Appointment Scheduling** - Efficient booking and management system
- **Clinical Operations** - Patient care workflows and treatments
- **Billing & Payments** - Payment processing and financial management
- **SMS Notifications** - Real-time alerts via Africa's Talking integration
- **Real-time Communication** - WebSocket support for live updates

---

## 🛠️ Technology Stack

### Backend
| Technology | Purpose | Version |
|-----------|---------|---------|
| **Node.js** | Runtime environment | >=18.0.0 |
| **Express.js** | Web framework | ^4.19.2 |
| **Prisma** | ORM & Database toolkit | ^7.10.0 |
| **PostgreSQL** | Database | (via Prisma adapter) |
| **JWT** | Authentication | ^9.0.2 |
| **bcrypt** | Password hashing | ^5.1.1 |
| **Socket.io** | Real-time WebSocket | ^4.7.5 |
| **Africa's Talking** | SMS/USSD gateway | ^0.7.0 |
| **Nodemailer** | Email service | ^6.9.14 |

### Security & Utilities
- **Helmet** - HTTP security headers
- **CORS** - Cross-origin resource sharing
- **Morgan** - HTTP request logging
- **node-cron** - Task scheduling
- **dotenv** - Environment management

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────┐
│       Frontend Application           │
│   (Flutter/Web Client)              │
└──────────────┬──────────────────────┘
               │
               │ HTTP/WebSocket
               ▼
┌─────────────────────────────────────┐
│      Express.js API Server          │
│   ├─ Authentication (JWT)           │
│   ├─ Route Handlers                 │
│   └─ Middleware (Auth, Validation)  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Prisma ORM Layer                   │
│  ├─ Query Generation                │
│   └─ Database Migrations            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   PostgreSQL Database               │
│  (Patient, Appointments, Billing)   │
└─────────────────────────────────────┘
```

**External Services:**
- Africa's Talking (SMS/USSD)
- Email Service (Nodemailer)
- Task Scheduler (node-cron)

---

## 📋 Prerequisites

Ensure you have the following installed:

- **Node.js** version 18.0.0 or higher
- **npm** or **yarn** package manager
- **PostgreSQL** database (local or remote)
- **Git** for version control

### Verify Installation
```bash
node --version      # Should be v18.0.0+
npm --version       # Should be v8.0.0+
psql --version      # PostgreSQL client
```

---

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/erisamuki/JRAPHA.git
cd JRAPHA
```

### 2. Navigate to Backend Directory
```bash
cd backend
```

### 3. Install Dependencies
```bash
npm install
```

This will automatically run the Prisma generate postinstall script.

### 4. Setup Environment Variables

Create a `.env` file in the `backend` directory:

```bash
# Database Configuration
DATABASE_URL="postgresql://user:password@localhost:5432/jrapha"

# Server Configuration
PORT=5000
NODE_ENV=development

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_here_min_32_chars
JWT_EXPIRY=7d

# CORS Configuration
CORS_ORIGIN=http://localhost:3000

# Africa's Talking API (SMS/USSD)
AFRICASTALKING_API_KEY=your_api_key_here
AFRICASTALKING_USERNAME=your_username_here

# Email Configuration (Nodemailer)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_app_password

# Application Settings
APP_NAME=JRapha
APP_VERSION=0.1.0
```

**⚠️ Important:** Never commit `.env` to version control. Use `.env.example` for reference.

---

## ⚙️ Configuration

### Database Configuration

The application uses PostgreSQL with Prisma ORM. Database schema is defined in `prisma/schema.prisma`.

**Key Configuration Files:**
- `prisma/schema.prisma` - Data model definitions
- `.env` - Database connection string

### Server Configuration

| Setting | Description | Default |
|---------|-------------|---------|
| `PORT` | Server port | 5000 |
| `NODE_ENV` | Environment (development/production) | development |
| `JWT_EXPIRY` | JWT token expiration | 7d |
| `CORS_ORIGIN` | Allowed frontend origin | http://localhost:3000 |

---

## 🎯 Running the Application

### Development Mode

Start the development server with hot-reload using **Nodemon**:

```bash
npm run dev
```

The server will start on `http://localhost:5000` (or configured PORT).

### Production Mode

```bash
npm start
```

### Verify Server is Running

```bash
curl http://localhost:5000/health
```

---

## 🗄️ Database Management

### Initialize Database Schema

```bash
npx prisma migrate dev --name init
```

This command:
1. Creates a migration file
2. Applies the migration to the database
3. Generates Prisma Client

### Apply Migrations

```bash
npx prisma migrate deploy
```

### Reset Database (⚠️ Clears all data)

```bash
npx prisma migrate reset
```

### View Database in Prisma Studio

```bash
npx prisma studio
```

Opens an interactive database browser at `http://localhost:5555`

### Generate Prisma Client

```bash
npx prisma generate
```

---

## 📚 API Documentation

### Authentication Endpoints

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword",
  "fullName": "John Doe",
  "role": "doctor"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "role": "doctor"
  }
}
```

### Patient Management

#### Get All Patients
```http
GET /api/patients
Authorization: Bearer <token>
```

#### Get Patient by ID
```http
GET /api/patients/:id
Authorization: Bearer <token>
```

#### Create Patient
```http
POST /api/patients
Authorization: Bearer <token>
Content-Type: application/json

{
  "firstName": "Jane",
  "lastName": "Doe",
  "email": "jane@example.com",
  "phoneNumber": "+256701234567",
  "dateOfBirth": "1990-01-01"
}
```

### Appointments

#### Create Appointment
```http
POST /api/appointments
Authorization: Bearer <token>
Content-Type: application/json

{
  "patientId": "uuid",
  "doctorId": "uuid",
  "appointmentDate": "2026-09-15T10:00:00Z",
  "reason": "Regular checkup"
}
```

### For complete API documentation, refer to the Swagger/OpenAPI spec (if available)

---

## 📁 Project Structure

```
JRAPHA/
├── backend/
│   ├── src/
│   │   ├── server.js              # Application entry point
│   │   ├── config/                # Configuration files
│   │   ├── routes/                # API route definitions
│   │   ├── controllers/           # Request handlers
│   │   ├── middleware/            # Custom middleware
│   │   ├── models/                # Data models (Prisma)
│   │   ├── services/              # Business logic
│   │   ├── utils/                 # Utility functions
│   │   └── validators/            # Input validation
│   ├── prisma/
│   │   ├── schema.prisma          # Database schema
│   │   └── migrations/            # Database migrations
│   ├── .env.example               # Environment template
│   ├── package.json               # Dependencies
│   └── README.md                  # Backend documentation
├── frontend/                       # Frontend application (Flutter/Web)
├── docs/                          # Documentation
└── README.md                      # This file
```

---

## 🔄 Development Workflow

### 1. Create a New Feature Branch
```bash
git checkout -b feature/patient-dashboard
```

### 2. Make Your Changes
- Write code following project conventions
- Run tests to ensure quality
- Update relevant documentation

### 3. Database Schema Changes

If modifying the database:
```bash
# Create a migration
npx prisma migrate dev --name add_new_field

# Review the migration
git diff prisma/migrations/

# Commit
git add .
git commit -m "feat: add new patient field"
```

### 4. Test Your Changes

```bash
# Run tests
npm test

# Lint code
npm run lint

# Format code
npm run format
```

### 5. Commit and Push
```bash
git add .
git commit -m "feat: implement patient dashboard"
git push origin feature/patient-dashboard
```

### 6. Create a Pull Request
- Provide clear PR description
- Reference related issues
- Request review from maintainers

---

## 🧪 Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Generate coverage report
npm run test:coverage
```

---

## 📝 Code Style & Linting

Maintain consistent code quality:

```bash
# Lint code
npm run lint

# Fix linting issues automatically
npm run lint:fix

# Format code
npm run format
```

---

## 🐛 Debugging

### Enable Debug Logs
```bash
DEBUG=jrapha:* npm run dev
```

### Debug with Node Inspector
```bash
node --inspect src/server.js
```

Then visit `chrome://inspect` in Chrome DevTools.

### Database Query Logging
Set in `.env`:
```bash
DATABASE_LOG=true
```

---

## 🔐 Security Considerations

1. **Environment Variables** - Never commit `.env` file
2. **JWT Secrets** - Use strong, randomly generated secrets (min 32 chars)
3. **Database** - Use strong passwords, limit connection sources
4. **CORS** - Only allow trusted origins in production
5. **Helmet** - Security headers configured automatically
6. **Rate Limiting** - Implement rate limiting for sensitive endpoints
7. **Input Validation** - All inputs validated before processing
8. **Password Hashing** - Bcrypt with salt rounds configured

---

## 📦 Deployment

### Prerequisites for Production
- PostgreSQL database hosted (AWS RDS, Heroku, etc.)
- Environment variables configured securely
- Node.js v18+ on production server
- Reverse proxy (Nginx/Apache)
- SSL certificates configured

### Deployment Steps

```bash
# 1. Clone repository on production server
git clone https://github.com/erisamuki/JRAPHA.git
cd JRAPHA/backend

# 2. Install dependencies
npm install --production

# 3. Set environment variables
nano .env  # Add production configuration

# 4. Run database migrations
npx prisma migrate deploy

# 5. Start application
npm start
```

### Using PM2 for Process Management

```bash
npm install -g pm2

# Start application
pm2 start src/server.js --name "jrapha"

# Monitor
pm2 monit

# Logs
pm2 logs jrapha
```

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### 1. Fork the Repository
```bash
git clone https://github.com/erisamuki/JRAPHA.git
cd JRAPHA
```

### 2. Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 3. Commit with Clear Messages
```bash
git commit -m "feat: add patient billing module"
```

Use conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting
- `refactor:` Code reorganization
- `test:` Test additions
- `chore:` Maintenance

### 4. Push and Create Pull Request
```bash
git push origin feature/your-feature-name
```

### 5. PR Requirements
- Clear description of changes
- Reference related issues
- Pass all CI checks
- At least one approval

---

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

---

## 🆘 Support & Contact

### Issues & Bug Reports
- GitHub Issues: [JRAPHA Issues](https://github.com/erisamuki/JRAPHA/issues)
- Include reproduction steps and environment info

### Questions & Discussion
- GitHub Discussions: [JRAPHA Discussions](https://github.com/erisamuki/JRAPHA/discussions)

### Contact
- **Developer:** Erisamuki
- **Email:** erisamukisa51@gmail.com
- **GitHub:** [@erisamuki](https://github.com/erisamuki)

---

## 📚 Additional Resources

- [Express.js Documentation](https://expressjs.com/)
- [Prisma Documentation](https://www.prisma.io/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc7519)
- [Africa's Talking API](https://africastalking.com/sms/api)

---

## 🎯 Roadmap

- [ ] Patient medical records module
- [ ] Prescription management system
- [ ] Lab results integration
- [ ] Insurance billing automation
- [ ] Multi-hospital support
- [ ] Mobile app development
- [ ] Analytics & reporting dashboard
- [ ] AI-powered diagnostics support
- [ ] Telemedicine integration
- [ ] HIPAA compliance certification

---

## ⭐ Acknowledgments

- Built with modern Node.js ecosystem
- Thanks to all contributors and maintainers

---

**Last Updated:** September 3, 2026  
**Version:** 0.1.0  
**Status:** Active Development

For the latest updates, visit the [GitHub repository](https://github.com/erisamuki/JRAPHA).
