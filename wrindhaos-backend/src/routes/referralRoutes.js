const express = require('express');
const router = express.Router();
const referralController = require('../controllers/referralController');
const { authenticateUser } = require('../middleware/authMiddleware');

router.use(authenticateUser);

router.get('/me', referralController.getMyReferrals);
router.post('/apply', referralController.applyReferral);

module.exports = router;
