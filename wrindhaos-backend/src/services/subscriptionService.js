const crypto = require('crypto');
const googlePlayService = require('./googlePlayService');
const { mockStore } = require('../config/supabase');
const { logAuditEvent } = require('../utils/auditLogger');
const AUDIT_EVENTS = require('../constants/auditEvents');
const { PLANS, SUBSCRIPTION_STATUSES } = require('../constants/entitlements');

/**
 * Verify and Process Google Play Subscription Purchase Token
 */
async function processGooglePlayPurchase(userId, purchaseToken, productId, ipAddress) {
  // Prevent Purchase Token Reuse Across Multiple Users
  for (const [subId, sub] of mockStore.subscriptions.entries()) {
    if (sub.purchase_token === purchaseToken && sub.user_id !== userId) {
      await logAuditEvent(userId, AUDIT_EVENTS.SECURITY_EVENT, { reason: 'purchase_token_reuse_attempt', purchaseToken }, ipAddress);
      throw {
        statusCode: 400,
        code: 'TOKEN_ALREADY_LINKED',
        message: 'This purchase token is already linked to another WrindhaOS account.',
      };
    }
  }

  // Verify Purchase Token Server-Side with Google Play Developer API
  const playData = await googlePlayService.verifyGooglePlayPurchaseToken(purchaseToken, productId);

  if (!playData.verified) {
    throw { statusCode: 400, code: 'INVALID_PURCHASE', message: 'Google Play subscription purchase verification failed.' };
  }

  // Update or Create Subscription Record
  const subscriptionId = crypto.randomUUID();
  const subRecord = {
    id: subscriptionId,
    user_id: userId,
    provider: 'google_play',
    product_id: productId,
    purchase_token: purchaseToken,
    order_id: playData.orderId,
    status: playData.status, // ACTIVE | CANCELLED | EXPIRED
    plan: PLANS.PREMIUM,
    auto_renewing: playData.autoRenewing,
    price: '₹299.00',
    currency: 'INR',
    started_at: new Date(playData.startTimeMillis).toISOString(),
    current_period_start: new Date().toISOString(),
    current_period_end: new Date(playData.expiryTimeMillis).toISOString(),
    cancelled_at: playData.cancelReason ? new Date().toISOString() : null,
    expired_at: playData.status === 'EXPIRED' ? new Date(playData.expiryTimeMillis).toISOString() : null,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  mockStore.subscriptions.set(subscriptionId, subRecord);

  // Update User Entitlement Status
  const user = mockStore.users.get(userId);
  if (user) {
    user.subscription_plan = PLANS.PREMIUM;
    user.subscription_status = playData.status;
    user.ads_enabled = false; // AD-FREE EXPERIENCE
    mockStore.users.set(userId, user);
  }

  await logAuditEvent(userId, AUDIT_EVENTS.SUBSCRIPTION_ACTIVATED, { productId, orderId: playData.orderId }, ipAddress);

  return {
    subscription: subRecord,
    userPlan: PLANS.PREMIUM,
    adsEnabled: false,
  };
}

/**
 * Get User's Active Subscription Info
 */
async function getUserSubscription(userId) {
  const user = mockStore.users.get(userId);
  const activeSub = Array.from(mockStore.subscriptions.values()).find(
    (s) => s.user_id === userId && s.status !== 'EXPIRED'
  );

  return {
    plan: user?.subscription_plan || PLANS.FREE,
    status: user?.subscription_status || SUBSCRIPTION_STATUSES.ACTIVE,
    productId: activeSub?.product_id || null,
    autoRenewing: activeSub?.auto_renewing ?? false,
    currentPeriodEnd: activeSub?.current_period_end || null,
    adsEnabled: user?.ads_enabled ?? true,
  };
}

/**
 * Process Subscription Expiry Downgrade
 * When subscription expires, plan returns to FREE, ads_enabled = TRUE, but user data is NEVER deleted!
 */
async function handleSubscriptionExpiry(userId) {
  const user = mockStore.users.get(userId);
  if (user) {
    user.subscription_plan = PLANS.FREE;
    user.subscription_status = SUBSCRIPTION_STATUSES.EXPIRED;
    user.ads_enabled = true;
    mockStore.users.set(userId, user);
  }
  await logAuditEvent(userId, AUDIT_EVENTS.SUBSCRIPTION_EXPIRED, {});
}

module.exports = {
  processGooglePlayPurchase,
  getUserSubscription,
  handleSubscriptionExpiry,
};
