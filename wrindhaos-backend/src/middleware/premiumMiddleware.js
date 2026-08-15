const entitlementService = require('../services/entitlementService');
const { sendError } = require('../utils/response');

/**
 * Enforce Feature Access (Ensures feature is enabled for user plan)
 */
function enforceFeatureAccess(featureKey) {
  return async (req, res, next) => {
    try {
      const userId = req.user.id;
      const isAllowed = await entitlementService.checkFeatureAccess(userId, featureKey);

      if (!isAllowed) {
        return sendError(
          res,
          `The ${featureKey} feature requires a Premium subscription. Upgrade to WrindhaOS Premium to unlock.`,
          'FEATURE_LOCKED',
          403
        );
      }
      next();
    } catch (err) {
      next(err);
    }
  };
}

/**
 * Enforce Feature Limit (Enforces max 2 habits/subjects limit for Free plan)
 */
function enforceFeatureLimit(featureKey, getCountFn, errorCode) {
  return async (req, res, next) => {
    try {
      const userId = req.user.id;
      const currentCount = await getCountFn(userId);
      const limitCheck = await entitlementService.checkFeatureLimit(userId, featureKey, currentCount);

      if (!limitCheck.allowed) {
        return sendError(
          res,
          limitCheck.message || `Free plan limit reached (${limitCheck.limit}). Upgrade to Premium for unlimited access.`,
          errorCode || 'LIMIT_REACHED',
          403
        );
      }
      next();
    } catch (err) {
      next(err);
    }
  };
}

module.exports = {
  enforceFeatureAccess,
  enforceFeatureLimit,
};
