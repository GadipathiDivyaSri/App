const { androidPublisher } = require('../config/googlePlay');
const config = require('../config/env');
const logger = require('../utils/logger');

/**
 * Verify Purchase Token with Google Play Developer API
 */
async function verifyGooglePlayPurchaseToken(purchaseToken, productId) {
  logger.info('Initiating server-side Google Play subscription verification', { productId });

  // Verify Package Name & Product ID match configured application
  if (productId !== config.googlePlay.subscriptionProductId) {
    throw {
      statusCode: 400,
      code: 'INVALID_PRODUCT_ID',
      message: `Invalid subscription product ID: ${productId}. Expected: ${config.googlePlay.subscriptionProductId}`,
    };
  }

  // Live Google Play Developer API verification
  if (androidPublisher) {
    try {
      const response = await androidPublisher.purchases.subscriptions.get({
        packageName: config.googlePlay.packageName,
        subscriptionId: productId,
        token: purchaseToken,
      });

      const subData = response.data;
      logger.info('Google Play Developer API response received', { subData });

      const expiryTimeMillis = parseInt(subData.expiryTimeMillis, 10);
      const isExpired = Date.now() > expiryTimeMillis;

      let status = 'ACTIVE';
      if (isExpired) {
        status = 'EXPIRED';
      } else if (subData.userCancellationTimeMillis) {
        status = 'CANCELLED'; // Retains premium access until period ends!
      } else if (subData.paymentState === 0) {
        status = 'PENDING';
      }

      return {
        verified: true,
        orderId: subData.orderId || `GPA.${Date.now()}`,
        status: status,
        autoRenewing: subData.autoRenewing ?? true,
        startTimeMillis: parseInt(subData.startTimeMillis || Date.now(), 10),
        expiryTimeMillis: expiryTimeMillis,
        cancelReason: subData.cancelReason,
      };
    } catch (err) {
      logger.error('Google Play Developer API error', err);
      throw {
        statusCode: 400,
        code: 'GOOGLE_PLAY_VERIFICATION_FAILED',
        message: `Google Play purchase verification failed: ${err.message}`,
      };
    }
  }

  // Fallback Simulation Mode for testing & local development
  logger.warn('Running Google Play Verification in Mock Mode');
  const now = Date.now();
  const thirtyDaysMillis = 30 * 24 * 60 * 60 * 1000;

  return {
    verified: true,
    orderId: `GPA.3301-4492-9812-${Date.now().toString().slice(-5)}`,
    status: 'ACTIVE',
    autoRenewing: true,
    startTimeMillis: now,
    expiryTimeMillis: now + thirtyDaysMillis,
  };
}

module.exports = {
  verifyGooglePlayPurchaseToken,
};
