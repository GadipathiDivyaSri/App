const entitlementService = require('../services/entitlementService');
const { sendSuccess } = require('../utils/response');

async function getEntitlements(req, res, next) {
  try {
    const entitlements = await entitlementService.getUserEntitlements(req.user.id);
    sendSuccess(res, entitlements, 'User feature entitlements retrieved.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getEntitlements,
};
