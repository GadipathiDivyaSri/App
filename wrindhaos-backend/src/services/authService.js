const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const config = require('../config/env');
const { mockStore } = require('../config/supabase');
const { logAuditEvent } = require('../utils/auditLogger');
const AUDIT_EVENTS = require('../constants/auditEvents');

/**
 * Generate JWT Session Token
 */
function generateToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      phone: user.phone_number,
      plan: user.subscription_plan || 'FREE',
      status: user.subscription_status || 'ACTIVE',
      adsEnabled: user.ads_enabled ?? true,
    },
    config.jwt.secret,
    { expiresIn: config.jwt.expiresIn }
  );
}

/**
 * Authenticate or Register via Email OTP
 */
async function authenticateEmail(email, ipAddress) {
  let user = Array.from(mockStore.users.values()).find((u) => u.email === email);
  let isNewUser = false;

  if (!user) {
    isNewUser = true;
    const userId = crypto.randomUUID();
    user = {
      id: userId,
      full_name: email.split('@')[0],
      email: email,
      phone_number: null,
      profile_image: null,
      subscription_plan: 'FREE',
      subscription_status: 'ACTIVE',
      ads_enabled: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      last_login_at: new Date().toISOString(),
    };
    mockStore.users.set(userId, user);

    // Record user_auth_identity
    mockStore.identities.set(`email_${email}`, {
      id: crypto.randomUUID(),
      user_id: userId,
      provider: 'email',
      provider_user_id: email,
      email: email,
    });

    await logAuditEvent(userId, AUDIT_EVENTS.USER_CREATED, { method: 'email_otp', email }, ipAddress);
  } else {
    user.last_login_at = new Date().toISOString();
  }

  await logAuditEvent(user.id, AUDIT_EVENTS.EMAIL_LOGIN, { email }, ipAddress);

  const token = generateToken(user);
  return { user, token, isNewUser };
}

/**
 * Authenticate or Register via Mobile OTP
 */
async function authenticateMobile(phone, ipAddress) {
  let user = Array.from(mockStore.users.values()).find((u) => u.phone_number === phone);
  let isNewUser = false;

  if (!user) {
    isNewUser = true;
    const userId = crypto.randomUUID();
    user = {
      id: userId,
      full_name: 'Mobile Student',
      email: null,
      phone_number: phone,
      profile_image: null,
      subscription_plan: 'FREE',
      subscription_status: 'ACTIVE',
      ads_enabled: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      last_login_at: new Date().toISOString(),
    };
    mockStore.users.set(userId, user);

    mockStore.identities.set(`phone_${phone}`, {
      id: crypto.randomUUID(),
      user_id: userId,
      provider: 'phone',
      provider_user_id: phone,
      phone: phone,
    });

    await logAuditEvent(userId, AUDIT_EVENTS.USER_CREATED, { method: 'mobile_otp', phone }, ipAddress);
  } else {
    user.last_login_at = new Date().toISOString();
  }

  await logAuditEvent(user.id, AUDIT_EVENTS.PHONE_LOGIN, { phone }, ipAddress);

  const token = generateToken(user);
  return { user, token, isNewUser };
}

/**
 * Authenticate via Google Sign-In (Server-side Token Verification)
 */
async function authenticateGoogle(idToken, ipAddress) {
  // Server-side Google Token Verification Simulation / OAuth Check
  if (!idToken) {
    throw { statusCode: 400, code: 'INVALID_GOOGLE_TOKEN', message: 'Google identity token required.' };
  }

  const googleEmail = 'alex.google@example.com';
  const googleId = 'g_sub_1092837465';

  let user = Array.from(mockStore.users.values()).find((u) => u.email === googleEmail);
  let isNewUser = false;

  if (!user) {
    isNewUser = true;
    const userId = crypto.randomUUID();
    user = {
      id: userId,
      full_name: 'Alex Johnson',
      email: googleEmail,
      phone_number: null,
      profile_image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      subscription_plan: 'FREE',
      subscription_status: 'ACTIVE',
      ads_enabled: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      last_login_at: new Date().toISOString(),
    };
    mockStore.users.set(userId, user);

    mockStore.identities.set(`google_${googleId}`, {
      id: crypto.randomUUID(),
      user_id: userId,
      provider: 'google',
      provider_user_id: googleId,
      email: googleEmail,
    });

    await logAuditEvent(userId, AUDIT_EVENTS.USER_CREATED, { method: 'google_sso', googleId }, ipAddress);
  } else {
    user.last_login_at = new Date().toISOString();
  }

  await logAuditEvent(user.id, AUDIT_EVENTS.GOOGLE_LOGIN, { googleEmail }, ipAddress);

  const token = generateToken(user);
  return { user, token, isNewUser };
}

module.exports = {
  authenticateEmail,
  authenticateMobile,
  authenticateGoogle,
  generateToken,
};
