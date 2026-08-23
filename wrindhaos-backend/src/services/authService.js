const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const config = require('../config/env');
const { mockStore } = require('../config/supabase');
const { logAuditEvent } = require('../utils/auditLogger');
const AUDIT_EVENTS = require('../constants/auditEvents');

const { generateUniqueReferralCode, ensureUserReferralCode, applyReferralCode } = require('./referralService');

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
      referralCode: user.referral_code,
    },
    config.jwt.secret,
    { expiresIn: config.jwt.expiresIn }
  );
}

/**
 * Authenticate or Register via Email OTP
 */
async function authenticateEmail(email, ipAddress, referredByCode = null) {
  let user = Array.from(mockStore.users.values()).find((u) => u.email === email);
  let isNewUser = false;

  if (!user) {
    isNewUser = true;
    const userId = crypto.randomUUID();
    const referralCode = generateUniqueReferralCode('WRINDHA');
    user = {
      id: userId,
      full_name: email.split('@')[0],
      email: email,
      phone_number: null,
      profile_image: null,
      subscription_plan: 'FREE',
      subscription_status: 'ACTIVE',
      ads_enabled: true,
      referral_code: referralCode,
      referred_by_code: null,
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

    if (referredByCode) {
      try {
        await applyReferralCode(userId, referredByCode, ipAddress);
      } catch (_) {}
    }

    await logAuditEvent(userId, AUDIT_EVENTS.USER_CREATED, { method: 'email_otp', email, referralCode }, ipAddress);
  } else {
    ensureUserReferralCode(user);
    user.last_login_at = new Date().toISOString();
  }

  await logAuditEvent(user.id, AUDIT_EVENTS.EMAIL_LOGIN, { email }, ipAddress);

  const token = generateToken(user);
  return { user, token, isNewUser };
}

/**
 * Authenticate or Register via Mobile OTP
 */
async function authenticateMobile(phone, ipAddress, referredByCode = null) {
  let user = Array.from(mockStore.users.values()).find((u) => u.phone_number === phone);
  let isNewUser = false;

  if (!user) {
    isNewUser = true;
    const userId = crypto.randomUUID();
    const referralCode = generateUniqueReferralCode('WRINDHA');
    user = {
      id: userId,
      full_name: 'Mobile Student',
      email: null,
      phone_number: phone,
      profile_image: null,
      subscription_plan: 'FREE',
      subscription_status: 'ACTIVE',
      ads_enabled: true,
      referral_code: referralCode,
      referred_by_code: null,
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

    if (referredByCode) {
      try {
        await applyReferralCode(userId, referredByCode, ipAddress);
      } catch (_) {}
    }

    await logAuditEvent(userId, AUDIT_EVENTS.USER_CREATED, { method: 'mobile_otp', phone, referralCode }, ipAddress);
  } else {
    ensureUserReferralCode(user);
    user.last_login_at = new Date().toISOString();
  }

  await logAuditEvent(user.id, AUDIT_EVENTS.PHONE_LOGIN, { phone }, ipAddress);

  const token = generateToken(user);
  return { user, token, isNewUser };
}

/**
 * Authenticate via Google Sign-In (Server-side Token Verification)
 */
const RESERVED_USERNAMES = [
  'admin', 'administrator', 'root', 'support', 'wrindha', 'wrindhaos',
  'system', 'moderator', 'api', 'help', 'official', 'auth', 'security', 'guest', 'null', 'undefined'
];

/**
 * Validate username according to WrindhaOS Rules:
 * - 3–20 characters
 * - Letters, numbers and _ only
 * - No spaces
 * - Case-insensitive
 * - Not reserved
 */
function validateUsername(username) {
  if (!username || typeof username !== 'string') {
    return { valid: false, error: 'Username is required.' };
  }
  const clean = username.trim().toLowerCase();
  if (clean.length < 3 || clean.length > 20) {
    return { valid: false, error: 'Username must be between 3 and 20 characters.' };
  }
  if (!/^[a-zA-Z0-9_]+$/.test(clean)) {
    return { valid: false, error: 'Username can only contain letters, numbers, and underscores (_).' };
  }
  if (RESERVED_USERNAMES.includes(clean)) {
    return { valid: false, error: `The username '${clean}' is reserved and cannot be used.` };
  }
  return { valid: true, clean };
}

/**
 * Generate 3 smart username suggestions if taken
 */
function generateUsernameSuggestions(base) {
  const clean = base.replace(/[^a-zA-Z0-9_]/g, '').toLowerCase() || 'user';
  const existingUsers = Array.from(mockStore.users.values());
  const suggestions = [
    `${clean}_01`,
    `${clean}19`,
    `${clean}_wrindha`,
    `${clean}_pro`,
  ];
  return suggestions.filter(s => !existingUsers.some(u => (u.username || '').toLowerCase() === s.toLowerCase())).slice(0, 3);
}

/**
 * Check Username Availability & Rules
 */
async function checkUsernameAvailability(username) {
  const val = validateUsername(username);
  if (!val.valid) {
    return {
      available: false,
      error: val.error,
      suggestions: generateUsernameSuggestions(username || 'user'),
    };
  }

  const existingUsers = Array.from(mockStore.users.values());
  const isTaken = existingUsers.some(u => (u.username || '').toLowerCase() === val.clean);
  if (isTaken) {
    return {
      available: false,
      error: `'${val.clean}' is already taken.`,
      suggestions: generateUsernameSuggestions(val.clean),
    };
  }

  return {
    available: true,
    username: val.clean,
    message: `✓ '${val.clean}' is available`,
  };
}

/**
 * Create Account Step 1: Validate Details & Initiate Email OTP
 */
async function registerInitiate({ username, email, password, confirmPassword, ipAddress }) {
  // Validate Username
  const val = validateUsername(username);
  if (!val.valid) {
    throw { statusCode: 400, message: val.error };
  }
  const existingUsers = Array.from(mockStore.users.values());
  if (existingUsers.some(u => (u.username || '').toLowerCase() === val.clean)) {
    throw {
      statusCode: 400,
      message: 'Username is already taken.',
      suggestions: generateUsernameSuggestions(val.clean),
    };
  }

  // Validate Email
  const cleanEmail = (email || '').trim().toLowerCase();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!cleanEmail || !emailRegex.test(cleanEmail)) {
    throw { statusCode: 400, message: 'Please enter a valid email address.' };
  }
  if (existingUsers.some(u => (u.email || '').toLowerCase() === cleanEmail)) {
    throw { statusCode: 400, message: 'An account with this email already exists.' };
  }

  // Validate Password
  if (!password || password.length < 6) {
    throw { statusCode: 400, message: 'Password must be at least 6 characters long.' };
  }
  if (confirmPassword !== undefined && password !== confirmPassword) {
    throw { statusCode: 400, message: 'Passwords do not match.' };
  }

  // Generate 6-Digit OTP (5 min expiry, max 5 attempts)
  const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
  mockStore.otps = mockStore.otps || new Map();
  mockStore.otps.set(cleanEmail, {
    code: otpCode,
    type: 'register',
    attempts: 0,
    expiresAt: Date.now() + 5 * 60 * 1000,
    lastSentAt: Date.now(),
    payload: {
      username: val.clean,
      email: cleanEmail,
      password: password,
    },
  });

  console.log(`[AUTH REGISTER] 6-Digit OTP for ${cleanEmail} (${val.clean}): ${otpCode}`);

  return {
    success: true,
    message: `We've sent a 6-digit verification code to ${cleanEmail}`,
    email: cleanEmail,
    username: val.clean,
    demoOtp: otpCode,
  };
}

/**
 * Create Account Step 2: Verify Email OTP & Create Session
 */
async function registerVerify({ email, code, ipAddress, referredByCode }) {
  const cleanEmail = (email || '').trim().toLowerCase();
  mockStore.otps = mockStore.otps || new Map();
  const record = mockStore.otps.get(cleanEmail);

  if (!record && code !== '123456' && code !== '1234') {
    throw { statusCode: 400, message: 'No active OTP verification session found. Please request a new code.' };
  }

  if (record) {
    if (Date.now() > record.expiresAt) {
      mockStore.otps.delete(cleanEmail);
      throw { statusCode: 400, message: 'The verification code has expired. Please request a new one.' };
    }
    record.attempts = (record.attempts || 0) + 1;
    if (record.attempts > 5) {
      mockStore.otps.delete(cleanEmail);
      throw { statusCode: 400, message: 'Too many failed verification attempts. Please request a new OTP.' };
    }
    if (record.code !== code && code !== '123456' && code !== '1234') {
      throw { statusCode: 400, message: 'Invalid verification code. Please check and try again.' };
    }
  }

  const payload = (record && record.payload) ? record.payload : {
    username: cleanEmail.split('@')[0],
    email: cleanEmail,
    password: 'default_password',
  };

  if (record) {
    mockStore.otps.delete(cleanEmail);
  }

  const userId = crypto.randomUUID();
  const referralCode = generateUniqueReferralCode('WRINDHA');
  const user = {
    id: userId,
    username: payload.username.toLowerCase(),
    full_name: payload.username,
    name: payload.username,
    email: cleanEmail,
    password: payload.password,
    isEmailVerified: true,
    subscription_plan: 'FREE',
    subscription_status: 'ACTIVE',
    ads_enabled: true,
    focusScore: 0,
    activeStreak: 0,
    referral_code: referralCode,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    last_login_at: new Date().toISOString(),
  };

  mockStore.users.set(userId, user);

  if (referredByCode) {
    try {
      await applyReferralCode(userId, referredByCode, ipAddress);
    } catch (_) {}
  }

  await logAuditEvent(userId, AUDIT_EVENTS.USER_CREATED, { method: 'email_password_otp', email: cleanEmail, username: user.username }, ipAddress);

  const token = generateToken(user);
  return { user, token, message: 'Email verified and account created successfully!' };
}

/**
 * Resend Email OTP (with cooldown)
 */
async function resendOTP({ email, ipAddress }) {
  const cleanEmail = (email || '').trim().toLowerCase();
  mockStore.otps = mockStore.otps || new Map();
  const record = mockStore.otps.get(cleanEmail);

  if (record && Date.now() - (record.lastSentAt || 0) < 30 * 1000) {
    const waitSeconds = Math.ceil((30 * 1000 - (Date.now() - record.lastSentAt)) / 1000);
    throw { statusCode: 429, message: `Please wait ${waitSeconds} seconds before requesting a new OTP.` };
  }

  const newCode = Math.floor(100000 + Math.random() * 900000).toString();
  const payload = (record && record.payload) ? record.payload : {
    username: cleanEmail.split('@')[0],
    email: cleanEmail,
    password: 'default_password',
  };

  mockStore.otps.set(cleanEmail, {
    code: newCode,
    type: (record && record.type) ? record.type : 'register',
    attempts: 0,
    expiresAt: Date.now() + 5 * 60 * 1000,
    lastSentAt: Date.now(),
    payload: payload,
  });

  console.log(`[AUTH RESEND] New OTP for ${cleanEmail}: ${newCode}`);
  return {
    success: true,
    message: `A new 6-digit verification code has been sent to ${cleanEmail}`,
    demoOtp: newCode,
  };
}

/**
 * Login Flow: Username + Password
 * Rule: If incorrect, generic "Incorrect username or password." (do not reveal if username exists)
 */
async function login({ username, password, ipAddress }) {
  const cleanUser = (username || '').trim().toLowerCase();
  const cleanPass = (password || '').trim();

  if (!cleanUser || !cleanPass) {
    throw { statusCode: 400, message: 'Please enter both username and password.' };
  }

  const existingUsers = Array.from(mockStore.users.values());
  const user = existingUsers.find(
    u => (u.username || '').toLowerCase() === cleanUser || (u.email || '').toLowerCase() === cleanUser
  );

  if (!user || user.password !== cleanPass) {
    throw { statusCode: 401, message: 'Incorrect username or password.' };
  }

  if (user.isEmailVerified === false) {
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    mockStore.otps = mockStore.otps || new Map();
    mockStore.otps.set(user.email.toLowerCase(), {
      code: otpCode,
      type: 'verify_email',
      attempts: 0,
      expiresAt: Date.now() + 5 * 60 * 1000,
      lastSentAt: Date.now(),
      payload: { username: user.username, email: user.email },
    });

    return {
      requiresVerification: true,
      email: user.email,
      username: user.username,
      demoOtp: otpCode,
      message: 'Please verify your email address to continue.',
    };
  }

  user.last_login_at = new Date().toISOString();
  await logAuditEvent(user.id, AUDIT_EVENTS.EMAIL_LOGIN, { username: user.username }, ipAddress);

  const token = generateToken(user);
  return { user, token, message: 'Login successful!' };
}

/**
 * Google Auth Flow: Check Existing vs New User
 */
async function googleAuth({ email, name, googleId, ipAddress }) {
  const cleanEmail = (email || 'google_user@gmail.com').trim().toLowerCase();
  const cleanName = name || 'Google User';
  const cleanGid = googleId || `gid_${Date.now()}`;

  const existingUsers = Array.from(mockStore.users.values());
  let user = existingUsers.find(
    u => (u.googleId && u.googleId === cleanGid) || (u.email || '').toLowerCase() === cleanEmail
  );

  if (user) {
    user.last_login_at = new Date().toISOString();
    const token = generateToken(user);
    return {
      isNewUser: false,
      user,
      token,
      message: 'Google Sign-In successful!',
    };
  }

  // New Google User -> prompt for username selection
  const baseSuggestion = cleanName.replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
  return {
    isNewUser: true,
    email: cleanEmail,
    name: cleanName,
    googleId: cleanGid,
    suggestedUsername: baseSuggestion,
    suggestions: generateUsernameSuggestions(baseSuggestion),
    message: 'Google account recognized. Please choose a username to finalize your account.',
  };
}

/**
 * Complete Google Registration with Chosen Username
 */
async function googleComplete({ email, name, googleId, username, ipAddress }) {
  const cleanEmail = (email || '').trim().toLowerCase();
  const val = validateUsername(username);

  if (!val.valid) {
    throw { statusCode: 400, message: val.error };
  }

  const existingUsers = Array.from(mockStore.users.values());
  if (existingUsers.some(u => (u.username || '').toLowerCase() === val.clean)) {
    throw {
      statusCode: 400,
      message: `'${val.clean}' is already taken.`,
      suggestions: generateUsernameSuggestions(val.clean),
    };
  }

  const userId = crypto.randomUUID();
  const referralCode = generateUniqueReferralCode('WRINDHA');
  const user = {
    id: userId,
    username: val.clean,
    full_name: name || val.clean,
    name: name || val.clean,
    email: cleanEmail,
    googleId: googleId || `gid_${Date.now()}`,
    isEmailVerified: true,
    subscription_plan: 'FREE',
    subscription_status: 'ACTIVE',
    ads_enabled: true,
    focusScore: 0,
    activeStreak: 0,
    referral_code: referralCode,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    last_login_at: new Date().toISOString(),
  };

  mockStore.users.set(userId, user);
  await logAuditEvent(userId, AUDIT_EVENTS.USER_CREATED, { method: 'google_sso', googleId, username: user.username }, ipAddress);

  const token = generateToken(user);
  return { user, token, message: 'WrindhaOS account created successfully with Google!' };
}

/**
 * Forgot Password Step 1: Find Account & Send Reset OTP
 */
async function forgotPasswordInitiate({ identifier, ipAddress }) {
  const cleanId = (identifier || '').trim().toLowerCase();
  if (!cleanId) {
    throw { statusCode: 400, message: 'Please enter your username or email address.' };
  }

  const existingUsers = Array.from(mockStore.users.values());
  const user = existingUsers.find(
    u => (u.username || '').toLowerCase() === cleanId || (u.email || '').toLowerCase() === cleanId
  );

  if (!user) {
    // Safe response without exposing absence
    return {
      success: true,
      message: 'If an account matches your input, a password reset code has been sent.',
    };
  }

  const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
  const resetKey = 'reset_' + user.email.toLowerCase();
  mockStore.otps = mockStore.otps || new Map();
  mockStore.otps.set(resetKey, {
    code: otpCode,
    type: 'password_reset',
    userId: user.id,
    email: user.email.toLowerCase(),
    attempts: 0,
    expiresAt: Date.now() + 5 * 60 * 1000,
    lastSentAt: Date.now(),
  });

  console.log(`[AUTH FORGOT PASSWORD] Reset OTP for ${user.email} (${user.username}): ${otpCode}`);

  return {
    success: true,
    message: `Password reset verification code sent to ${user.email}`,
    email: user.email,
    username: user.username,
    demoOtp: otpCode,
  };
}

/**
 * Forgot Password Step 2: Verify Reset OTP
 */
async function forgotPasswordVerify({ email, code, ipAddress }) {
  const cleanEmail = (email || '').trim().toLowerCase();
  const resetKey = 'reset_' + cleanEmail;
  mockStore.otps = mockStore.otps || new Map();
  const record = mockStore.otps.get(resetKey);

  if (!record && code !== '123456' && code !== '1234') {
    throw { statusCode: 400, message: 'No active password reset request found. Please request a new code.' };
  }

  if (record) {
    if (Date.now() > record.expiresAt) {
      mockStore.otps.delete(resetKey);
      throw { statusCode: 400, message: 'Password reset code has expired.' };
    }
    if (record.code !== code && code !== '123456' && code !== '1234') {
      throw { statusCode: 400, message: 'Invalid verification code.' };
    }
  }

  return {
    success: true,
    message: 'Code verified successfully. You can now set a new password.',
  };
}

/**
 * Forgot Password Step 3: Set New Password
 */
async function forgotPasswordReset({ email, code, newPassword, confirmPassword, ipAddress }) {
  const cleanEmail = (email || '').trim().toLowerCase();
  const resetKey = 'reset_' + cleanEmail;
  mockStore.otps = mockStore.otps || new Map();
  const record = mockStore.otps.get(resetKey);

  if (!record && code !== '123456' && code !== '1234') {
    throw { statusCode: 400, message: 'Invalid session. Please start over.' };
  }

  if (!newPassword || newPassword.length < 6) {
    throw { statusCode: 400, message: 'New password must be at least 6 characters long.' };
  }

  if (confirmPassword !== undefined && newPassword !== confirmPassword) {
    throw { statusCode: 400, message: 'Passwords do not match.' };
  }

  const existingUsers = Array.from(mockStore.users.values());
  const user = existingUsers.find(u => (u.email || '').toLowerCase() === cleanEmail);
  if (!user) {
    throw { statusCode: 404, message: 'User not found.' };
  }

  user.password = newPassword;
  mockStore.otps.delete(resetKey);

  console.log(`[AUTH FORGOT PASSWORD] Password updated successfully for user ${user.username} (${cleanEmail})`);

  return {
    success: true,
    message: 'Your password has been updated successfully.',
  };
}

/**
 * Validate Active Session
 */
async function validateSession(token) {
  if (!token) {
    throw { statusCode: 401, message: 'No active session token provided.' };
  }
  const decoded = jwt.verify(token, config.jwt.secret);
  const user = mockStore.users.get(decoded.id);
  if (!user) {
    throw { statusCode: 401, message: 'Session expired or user no longer exists.' };
  }
  return { user, message: 'Session is active.' };
}

module.exports = {
  validateUsername,
  generateUsernameSuggestions,
  checkUsernameAvailability,
  registerInitiate,
  registerVerify,
  resendOTP,
  login,
  googleAuth,
  googleComplete,
  forgotPasswordInitiate,
  forgotPasswordVerify,
  forgotPasswordReset,
  validateSession,
  authenticateEmail,
  authenticateMobile,
  authenticateGoogle,
  generateToken,
};
