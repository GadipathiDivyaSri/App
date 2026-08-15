const { PLANS, PLAN_LIMITS } = require('../constants/entitlements');
const { mockStore } = require('../config/supabase');

/**
 * Get User Entitlement Overview
 */
async function getUserEntitlements(userId) {
  const user = mockStore.users.get(userId) || {
    subscription_plan: PLANS.FREE,
    subscription_status: 'ACTIVE',
    ads_enabled: true,
  };

  const plan = user.subscription_plan || PLANS.FREE;
  const config = PLAN_LIMITS[plan] || PLAN_LIMITS[PLANS.FREE];

  return {
    plan: plan,
    subscriptionStatus: user.subscription_status || 'ACTIVE',
    adsEnabled: config.adsEnabled,
    features: config.features,
  };
}

/**
 * Check if a feature is enabled for user's plan
 */
async function checkFeatureAccess(userId, featureKey) {
  const entitlements = await getUserEntitlements(userId);
  const featureConfig = entitlements.features[featureKey];

  if (!featureConfig) return false;
  return featureConfig.enabled === true;
}

/**
 * Check if user has exceeded usage limit for a feature (e.g. Max 2 Habits for FREE)
 */
async function checkFeatureLimit(userId, featureKey, currentCount) {
  const entitlements = await getUserEntitlements(userId);
  const featureConfig = entitlements.features[featureKey];

  if (!featureConfig || !featureConfig.enabled) {
    return { allowed: false, message: 'Feature is disabled for your current plan.' };
  }

  // NULL limit means unlimited
  if (featureConfig.limit === null || featureConfig.limit === undefined) {
    return { allowed: true, limit: null };
  }

  if (currentCount >= featureConfig.limit) {
    return {
      allowed: false,
      limit: featureConfig.limit,
      message: `Free plan is limited to ${featureConfig.limit} ${featureKey}. Upgrade to WrindhaOS Premium for unlimited usage.`,
    };
  }

  return { allowed: true, limit: featureConfig.limit };
}

module.exports = {
  getUserEntitlements,
  checkFeatureAccess,
  checkFeatureLimit,
};
