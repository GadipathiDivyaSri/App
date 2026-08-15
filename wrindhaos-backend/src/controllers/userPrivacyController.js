const { sendSuccess, sendError } = require('../utils/response');
const { logAuditEvent } = require('../utils/auditLogger');

// In-Memory Storage for Deletion Requests & Consents
const privacyStore = {
  deletionRequests: new Map(),
  userConsents: new Map(),
};

/**
 * Initiate Account Deletion Request (User Self-Service)
 */
async function requestAccountDeletion(req, res, next) {
  try {
    const userId = req.user.id;
    const { reason } = req.body;

    const record = {
      id: `del_${Date.now()}`,
      user_id: userId,
      status: 'REQUESTED',
      requested_at: new Date().toISOString(),
      notes: reason ? 'User-provided reason for account deletion' : 'Self-service account deletion requested',
    };

    privacyStore.deletionRequests.set(userId, record);

    await logAuditEvent(userId, 'USER_ACCOUNT_DELETION_REQUESTED', { status: 'REQUESTED' }, req.ip);

    sendSuccess(res, { deletionRequest: record }, 'Account deletion request submitted successfully.');
  } catch (err) {
    next(err);
  }
}

/**
 * Get Current Account Deletion Status
 */
async function getAccountDeletionStatus(req, res, next) {
  try {
    const userId = req.user.id;
    const request = privacyStore.deletionRequests.get(userId) || null;

    sendSuccess(res, { deletionRequest: request }, 'Account deletion status retrieved.');
  } catch (err) {
    next(err);
  }
}

/**
 * Record User Privacy Consent
 */
async function recordUserConsent(req, res, next) {
  try {
    const userId = req.user.id;
    const { policy_type, policy_version } = req.body;

    if (!policy_type || !policy_version) {
      return sendError(res, 'policy_type and policy_version are required.', 'VALIDATION_ERROR', 400);
    }

    const consentRecord = {
      id: `consent_${Date.now()}`,
      user_id: userId,
      policy_type,
      policy_version,
      accepted_at: new Date().toISOString(),
      ip_address: req.ip,
    };

    const key = `${userId}_${policy_type}`;
    privacyStore.userConsents.set(key, consentRecord);

    await logAuditEvent(userId, 'USER_CONSENT_RECORDED', { policy_type, policy_version }, req.ip);

    sendSuccess(res, { consent: consentRecord }, 'User policy consent recorded successfully.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  requestAccountDeletion,
  getAccountDeletionStatus,
  recordUserConsent,
};
