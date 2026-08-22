const express = require('express');
const router = express.Router();

const { verifyToken, requireRole } = require('../../middleware/auth.middleware');
const { registerPatient, searchPatients, getPatient } = require('./patients.controller');
const {
  createVisit, getOpdDashboard, getInpatientDashboard, updateVisitStatus,
} = require('./visits.controller');
const { createAppointment, getAppointments } = require('./appointments.controller');

// Reception and admin can both view/act on all reception endpoints per spec
const allowed = requireRole('reception', 'admin');

router.use(verifyToken, allowed);

// Patients
router.post('/patients', registerPatient);
router.get('/patients', searchPatients);
router.get('/patients/:id', getPatient);

// Visits (OPD + in-patient dashboards)
router.post('/visits', createVisit);
router.get('/visits/opd', getOpdDashboard);
router.get('/visits/inpatient', getInpatientDashboard);
router.patch('/visits/:id/status', updateVisitStatus);

// Appointments
router.post('/appointments', createAppointment);
router.get('/appointments', getAppointments);

module.exports = router;