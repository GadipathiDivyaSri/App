const referralService = require('../services/referralService');
const { sendSuccess, sendError } = require('../utils/response');

/**
 * Get current user's referral code, statistics, discount and reward history
 * GET /api/v1/referrals/me
 */
async function getMyReferrals(req, res, next) {
  try {
    const userId = req.user.id;
    const summary = await referralService.getUserReferralSummary(userId);
    sendSuccess(res, summary, 'Referral summary retrieved.');
  } catch (err) {
    next(err);
  }
}

/**
 * Apply a referral code to authenticated account
 * POST /api/v1/referrals/apply
 */
async function applyReferral(req, res, next) {
  try {
    const userId = req.user.id;
    const { referralCode } = req.body;

    if (!referralCode) {
      return sendError(res, 'Referral code is required.', 'MISSING_CODE', 400);
    }

    const result = await referralService.applyReferralCode(userId, referralCode, req.ip);
    sendSuccess(res, result, result.message, 201);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getMyReferrals,
  applyReferral,
};
