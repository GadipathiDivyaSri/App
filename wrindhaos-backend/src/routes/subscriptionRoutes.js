const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');
const { authenticateUser } = require('../middleware/authMiddleware');
const { subscriptionRateLimiter } = require('../middleware/rateLimitMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');

// Public Webhook Endpoint for Google Play Real-Time Notifications
router.post('/google/webhook', subscriptionController.handleGooglePlayWebhook);

// Authenticated Endpoints
router.use(authenticateUser);

router.post(
  '/google/verify',
  subscriptionRateLimiter,
  validateBody(['purchaseToken', 'productId']),
  subscriptionController.verifyGooglePlaySubscription
);

router.get('/me', subscriptionController.getMySubscription);

module.exports = router;
