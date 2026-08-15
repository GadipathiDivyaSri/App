const express = require('express');
const router = express.Router();
const entitlementController = require('../controllers/entitlementController');
const { authenticateUser } = require('../middleware/authMiddleware');

router.use(authenticateUser);

router.get('/', entitlementController.getEntitlements);

module.exports = router;
