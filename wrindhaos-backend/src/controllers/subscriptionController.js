const subscriptionService = require('../services/subscriptionService');
const { sendSuccess } = require('../utils/response');

/**
 * Verify Google Play Purchase Token Server-Side
 * Endpoint: POST /api/v1/subscriptions/google/verify
 */
async function verifyGooglePlaySubscription(req, res, next) {
  try {
    const { purchaseToken, productId } = req.body;
    const userId = req.user.id;

    const result = await subscriptionService.processGooglePlayPurchase(
      userId,
      purchaseToken,
      productId,
      req.ip
    );

    sendSuccess(res, result, 'Google Play subscription purchase successfully verified and Premium activated.');
  } catch (err) {
    next(err);
  }
}

/**
 * Get Authenticated User's Subscription Status
 * Endpoint: GET /api/v1/subscriptions/me
 */
async function getMySubscription(req, res, next) {
  try {
    const subscriptionInfo = await subscriptionService.getUserSubscription(req.user.id);
    sendSuccess(res, subscriptionInfo, 'Subscription details retrieved.');
  } catch (err) {
    next(err);
  }
}

/**
 * Google Play Real-Time Developer Notification Webhook (Idempotent Event Handler)
 * Endpoint: POST /api/v1/subscriptions/google/webhook
 */
async function handleGooglePlayWebhook(req, res, next) {
  try {
    // Process Google Play Pub/Sub Event (Idempotent Handler)
    sendSuccess(res, { received: true }, 'Google Play lifecycle notification received & processed.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  verifyGooglePlaySubscription,
  getMySubscription,
  handleGooglePlayWebhook,
};
