const crypto = require('crypto');
const { mockStore } = require('../config/supabase');
const { logAuditEvent } = require('../utils/auditLogger');
const AUDIT_EVENTS = require('../constants/auditEvents');

/**
 * Generate a cryptographically secure, unique uppercase referral code.
 * Example: WRINDHA7K92
 */
function generateUniqueReferralCode(prefix = 'WRINDHA') {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid ambiguous chars (O, 0, 1, I)
  let attempts = 0;

  while (attempts < 100) {
    let randomPart = '';
    const bytes = crypto.randomBytes(4);
    for (let i = 0; i < 4; i++) {
      randomPart += chars[bytes[i] % chars.length];
    }
    const candidate = `${prefix}${randomPart}`;

    // Verify uniqueness across all users
    const exists = Array.from(mockStore.users.values()).some(
      (u) => u.referral_code === candidate
    );

    if (!exists) {
      return candidate;
    }
    attempts++;
  }

  return `${prefix}${Date.now().toString(36).toUpperCase()}`;
}

/**
 * Ensure user has a referral code generated and persisted
 */
function ensureUserReferralCode(user) {
  if (!user.referral_code) {
    user.referral_code = generateUniqueReferralCode('WRINDHA');
    user.updated_at = new Date().toISOString();
    mockStore.users.set(user.id, user);
  }
  return user.referral_code;
}

/**
 * Apply a referral code during or after registration
 */
async function applyReferralCode(referredUserId, referralCode, ipAddress) {
  if (!referralCode || typeof referralCode !== 'string') {
    throw { statusCode: 400, code: 'INVALID_CODE', message: 'Referral code is required.' };
  }

  const cleanCode = referralCode.trim().toUpperCase();

  // Find Referrer User
  const referrer = Array.from(mockStore.users.values()).find(
    (u) => u.referral_code === cleanCode
  );

  if (!referrer) {
    throw { statusCode: 404, code: 'REFERRAL_CODE_NOT_FOUND', message: 'Invalid referral code entered.' };
  }

  // Anti-Abuse 1: Prevent self-referral
  if (referrer.id === referredUserId) {
    throw { statusCode: 400, code: 'SELF_REFERRAL_FORBIDDEN', message: 'You cannot use your own referral code.' };
  }

  // Anti-Abuse 2: Prevent multiple referrals for the same referred user
  const existingReferral = Array.from(mockStore.referrals.values()).find(
    (r) => r.referred_user_id === referredUserId
  );

  if (existingReferral) {
    throw { statusCode: 400, code: 'REFERRAL_ALREADY_APPLIED', message: 'A referral code has already been applied to this account.' };
  }

  // Create pending referral record
  const referralId = crypto.randomUUID();
  const referralRecord = {
    id: referralId,
    referrer_user_id: referrer.id,
    referred_user_id: referredUserId,
    referral_code: cleanCode,
    status: 'PENDING',
    created_at: new Date().toISOString(),
    qualified_at: null,
  };

  mockStore.referrals.set(referralId, referralRecord);

  // Link to user profile
  const referredUser = mockStore.users.get(referredUserId);
  if (referredUser) {
    referredUser.referred_by_code = cleanCode;
    mockStore.users.set(referredUserId, referredUser);
  }

  await logAuditEvent(referredUserId, 'REFERRAL_APPLIED', { referrerId: referrer.id, code: cleanCode }, ipAddress);

  return {
    success: true,
    referral: referralRecord,
    message: 'Referral code applied successfully. Reward will activate upon subscription purchase.',
  };
}

/**
 * Qualify referral when referred user successfully pays for subscription
 */
async function qualifyReferralOnPayment(payingUserId, orderId) {
  const pendingReferral = Array.from(mockStore.referrals.values()).find(
    (r) => r.referred_user_id === payingUserId && r.status === 'PENDING'
  );

  if (!pendingReferral) {
    return null; // No pending referral to qualify
  }

  // Mark Referral as QUALIFIED
  pendingReferral.status = 'QUALIFIED';
  pendingReferral.qualified_at = new Date().toISOString();
  pendingReferral.order_id = orderId;
  mockStore.referrals.set(pendingReferral.id, pendingReferral);

  // Grant 10% Discount Referral Reward to Referrer
  const rewardId = crypto.randomUUID();
  const rewardRecord = {
    id: rewardId,
    referral_id: pendingReferral.id,
    referrer_user_id: pendingReferral.referrer_user_id,
    discount_percentage: 10,
    status: 'ACTIVE',
    applicable_billing_cycle: 1,
    earned_at: new Date().toISOString(),
    used_at: null,
    expires_at: null,
  };

  mockStore.referralRewards.set(rewardId, rewardRecord);

  await logAuditEvent(
    pendingReferral.referrer_user_id,
    'REFERRAL_QUALIFIED_REWARD_ISSUED',
    { referralId: pendingReferral.id, rewardId, payingUserId }
  );

  return { referral: pendingReferral, reward: rewardRecord };
}

/**
 * Get user's active referral discount status for next billing cycle
 */
function getActiveReferralDiscount(userId) {
  const activeRewards = Array.from(mockStore.referralRewards.values()).filter(
    (r) => r.referrer_user_id === userId && r.status === 'ACTIVE'
  );

  if (activeRewards.length === 0) {
    return { hasDiscount: false, discountPercentage: 0, rewardId: null, availableRewardsCount: 0 };
  }

  // Max 10% discount per billing cycle
  return {
    hasDiscount: true,
    discountPercentage: 10,
    rewardId: activeRewards[0].id,
    availableRewardsCount: activeRewards.length,
  };
}

/**
 * Consume one referral reward upon billing completion
 */
function consumeReferralReward(rewardId, billingCycleDetails = {}) {
  const reward = mockStore.referralRewards.get(rewardId);
  if (reward && reward.status === 'ACTIVE') {
    reward.status = 'USED';
    reward.used_at = new Date().toISOString();
    reward.billing_details = billingCycleDetails;
    mockStore.referralRewards.set(rewardId, reward);
    return reward;
  }
  return null;
}

/**
 * Get complete referral summary for user profile / referral dashboard
 */
async function getUserReferralSummary(userId) {
  const user = mockStore.users.get(userId);
  if (!user) {
    throw { statusCode: 404, code: 'USER_NOT_FOUND', message: 'User not found.' };
  }

  const referralCode = ensureUserReferralCode(user);

  const userReferrals = Array.from(mockStore.referrals.values()).filter(
    (r) => r.referrer_user_id === userId
  );

  const pendingCount = userReferrals.filter((r) => r.status === 'PENDING').length;
  const qualifiedCount = userReferrals.filter((r) => r.status === 'QUALIFIED' || r.status === 'REWARDED').length;

  const discountInfo = getActiveReferralDiscount(userId);

  const activities = userReferrals.map((r) => {
    const referee = mockStore.users.get(r.referred_user_id);
    return {
      id: r.id,
      name: referee?.full_name || 'Friend',
      status: r.status,
      date: new Date(r.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }).toUpperCase(),
      discountPercent: 10,
      isApplied: r.status === 'QUALIFIED' || r.status === 'REWARDED',
    };
  });

  return {
    referralCode,
    successfulReferrals: qualifiedCount,
    pendingReferrals: pendingCount,
    activeDiscountPercent: discountInfo.discountPercentage,
    hasActiveDiscount: discountInfo.hasDiscount,
    queuedRewardsCount: discountInfo.availableRewardsCount,
    activities,
  };
}

module.exports = {
  generateUniqueReferralCode,
  ensureUserReferralCode,
  applyReferralCode,
  qualifyReferralOnPayment,
  getActiveReferralDiscount,
  consumeReferralReward,
  getUserReferralSummary,
};
