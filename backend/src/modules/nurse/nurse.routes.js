const express = require('express');
const router = express.Router();

const { verifyToken, requireRole } = require('../../middleware/auth.middleware');
const { getNurseQueue, recordVitals, getVitalsForVisit } = require('./vitals.controller');

router.use(verifyToken, requireRole('nurse', 'admin'));

router.get('/queue', getNurseQueue);
router.post('/vitals', recordVitals);
router.get('/vitals/:visit_id', getVitalsForVisit);

module.exports = router;