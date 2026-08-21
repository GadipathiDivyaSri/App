const crypto = require('crypto');
const googlePlayService = require('./googlePlayService');
const referralService = require('./referralService');
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
    price: '₹59.00',
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

  // Qualify referral if this user was referred by someone
  if (playData.status === 'ACTIVE') {
    await referralService.qualifyReferralOnPayment(userId, playData.orderId);
  }

  await logAuditEvent(userId, AUDIT_EVENTS.SUBSCRIPTION_ACTIVATED, { productId, orderId: playData.orderId }, ipAddress);

  return {
    subscription: subRecord,
    userPlan: PLANS.PREMIUM,
    adsEnabled: false,
  };
}

/**
 * Process In-App Direct / Mock Checkout with Referral Discount applied
 */
async function checkoutSubscription(userId, plan = 'PREMIUM', basePrice = 59.0, ipAddress = '127.0.0.1') {
  const parsedPrice = typeof basePrice === 'number' ? basePrice : parseFloat(basePrice) || 59.0;
  
  // 1. Check for Active Referral Reward
  const discountInfo = referralService.getActiveReferralDiscount(userId);
  let discountPercentage = 0;
  let discountAmount = 0.0;
  let finalAmount = parsedPrice;
  let appliedRewardId = null;

  if (discountInfo.hasDiscount && discountInfo.rewardId) {
    discountPercentage = Math.min(discountInfo.discountPercentage, 10); // Max 10% discount policy
    discountAmount = Math.round((parsedPrice * (discountPercentage / 100.0)) * 100) / 100;
    finalAmount = Math.round((parsedPrice - discountAmount) * 100) / 100;
    appliedRewardId = discountInfo.rewardId;

    // Consume referral reward so it cannot be used again
    referralService.consumeReferralReward(appliedRewardId, {
      basePrice: parsedPrice,
      discountAmount,
      finalAmount,
      billingCycle: 1,
    });
  }

  const orderId = `GPA.WRINDHA-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
  const subscriptionId = crypto.randomUUID();
  const subRecord = {
    id: subscriptionId,
    user_id: userId,
    provider: 'in_app_billing',
    product_id: plan === 'PREMIUM_YEARLY' ? 'wrindhaos_premium_yearly' : 'wrindhaos_premium_monthly',
    purchase_token: `token_${crypto.randomBytes(16).toString('hex')}`,
    order_id: orderId,
    status: 'ACTIVE',
    plan: PLANS.PREMIUM,
    auto_renewing: true,
    price: `₹${finalAmount.toFixed(2)}`,
    currency: 'INR',
    original_price: parsedPrice,
    discount_amount: discountAmount,
    discount_percentage: discountPercentage,
    final_amount: finalAmount,
    reward_id_applied: appliedRewardId,
    started_at: new Date().toISOString(),
    current_period_start: new Date().toISOString(),
    current_period_end: new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString(),
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  mockStore.subscriptions.set(subscriptionId, subRecord);

  // Update user plan
  const user = mockStore.users.get(userId);
  if (user) {
    user.subscription_plan = PLANS.PREMIUM;
    user.subscription_status = 'ACTIVE';
    user.ads_enabled = false;
    mockStore.users.set(userId, user);
  }

  // Qualify any referrer whose code was used by this paying user!
  await referralService.qualifyReferralOnPayment(userId, orderId);

  await logAuditEvent(
    userId,
    AUDIT_EVENTS.SUBSCRIPTION_ACTIVATED,
    { orderId, basePrice: parsedPrice, discountAmount, finalAmount, appliedRewardId },
    ipAddress
  );

  return {
    success: true,
    subscription: subRecord,
    pricing: {
      originalPrice: parsedPrice,
      discountPercentage,
      discountAmount,
      finalAmount,
    },
    userPlan: PLANS.PREMIUM,
    adsEnabled: false,
    message: discountPercentage > 0
      ? `Subscription activated with ${discountPercentage}% referral discount! Final price: ₹${finalAmount.toFixed(2)}`
      : `Subscription activated! Price: ₹${finalAmount.toFixed(2)}`,
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

  const discountInfo = referralService.getActiveReferralDiscount(userId);

  return {
    plan: user?.subscription_plan || PLANS.FREE,
    status: user?.subscription_status || SUBSCRIPTION_STATUSES.ACTIVE,
    productId: activeSub?.product_id || null,
    autoRenewing: activeSub?.auto_renewing ?? false,
    currentPeriodEnd: activeSub?.current_period_end || null,
    adsEnabled: user?.ads_enabled ?? true,
    activeReferralDiscount: discountInfo,
  };
}

/**
 * Process Subscription Expiry Downgrade
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
  checkoutSubscription,
  getUserSubscription,
  handleSubscriptionExpiry,
};
