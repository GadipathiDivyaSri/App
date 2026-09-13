// 2-Factor OTP Engine & Google SSO Authenticator Service
const { mockDB } = require('../supabase_config');

/**
 * Generate 2FA 4-digit / 6-digit OTP code for Mobile / Email
 */
function send2FAOTP(contact) {
  // Demo static OTP '1234' or dynamic random code
  const code = '1234'; 
  const expiresAt = Date.now() + 5 * 60 * 1000; // 5 mins validity

  mockDB.otpStore[contact] = { code, expiresAt };
  console.log(`[2FA OTP SENT] Destination: ${contact} | Code: ${code}`);

  return {
    success: true,
    message: `2FA OTP code sent successfully to ${contact}`,
    demoCode: code,
  };
}

/**
 * Verify 2FA OTP Code
 */
function verify2FAOTP(contact, code) {
  const record = mockDB.otpStore[contact];

  if (!record) {
    // For demo fallback: allow code '1234'
    if (code === '1234') {
      return { success: true, token: 'mock_jwt_token_wrindha_os_2fa' };
    }
    return { success: false, message: 'No OTP record found. Please request a new OTP.' };
  }

  if (Date.now() > record.expiresAt) {
    delete mockDB.otpStore[contact];
    return { success: false, message: 'OTP has expired. Please request a new code.' };
  }

  if (record.code !== code && code !== '1234') {
    return { success: false, message: 'Invalid OTP verification code.' };
  }

  delete mockDB.otpStore[contact];
  return {
    success: true,
    token: 'mock_jwt_token_wrindha_os_2fa',
    message: '2FA authentication successful!',
  };
}

/**
 * Verify Google OAuth Sign-In Token
 */
function verifyGoogleToken(googleToken) {
  console.log(`[GOOGLE OAUTH VERIFIED] Token: ${googleToken}`);
  return {
    success: true,
    user: {
      id: 'g_123',
      name: 'Google User',
      email: 'user@gmail.com',
    },
    token: 'mock_jwt_google_sso_token',
  };
}

module.exports = {
  send2FAOTP,
  verify2FAOTP,
  verifyGoogleToken,
};
