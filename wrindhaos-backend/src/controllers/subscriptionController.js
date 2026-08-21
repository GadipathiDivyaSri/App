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
 * In-App / Web Subscription Checkout with Referral Discount applied
 * Endpoint: POST /api/v1/subscriptions/checkout
 */
async function checkoutSubscription(req, res, next) {
  try {
    const { plan, basePrice } = req.body;
    const userId = req.user.id;

    const result = await subscriptionService.checkoutSubscription(
      userId,
      plan || 'PREMIUM',
      basePrice || 59.0,
      req.ip
    );

    sendSuccess(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

async function handleGooglePlayWebhook(req, res, next) {
  try {
    sendSuccess(res, { received: true }, 'Google Play lifecycle notification received & processed.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  verifyGooglePlaySubscription,
  checkoutSubscription,
  getMySubscription,
  handleGooglePlayWebhook,
};
