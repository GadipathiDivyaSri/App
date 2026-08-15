const express = require('express');
const router = express.Router();
const userPrivacyController = require('../controllers/userPrivacyController');
const { authenticateUser } = require('../middleware/authMiddleware');

router.use(authenticateUser);

// Account Deletion Requests
router.post('/account-deletion', userPrivacyController.requestAccountDeletion);
router.get('/account-deletion/status', userPrivacyController.getAccountDeletionStatus);

// User Privacy Consents
router.post('/consents', userPrivacyController.recordUserConsent);

module.exports = router;
