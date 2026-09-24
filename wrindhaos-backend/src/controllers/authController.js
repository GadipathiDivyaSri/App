const msg91Service = require('../services/msg91Service');
const otpService = require('../services/otpService');
const authService = require('../services/authService');
const jwt = require('jsonwebtoken');
const config = require('../config/env');
const { sendSuccess, sendError } = require('../utils/response');

/**
 * Verify MSG91 Widget Access Token & Issue WrindhaOS App Session
 * Architecture: Flutter (Widget) -> accessToken -> Backend -> MSG91 Server -> Verified Email -> Supabase User -> App JWT
 */
async function verifyMsg91Token(req, res, next) {
  try {
    const { accessToken, referredByCode } = req.body;
    const { email } = await msg91Service.verifyAccessToken(accessToken);
    const authResult = await authService.authenticateEmail(email, req.ip, referredByCode);
    sendSuccess(res, authResult, 'MSG91 Email authentication verified successfully.');
  } catch (err) {
    next(err);
  }
}

async function requestEmailOTP(req, res, next) {
  try {
    const { email } = req.body;
    const result = await otpService.generateAndSendOTP(email, 'email');
    sendSuccess(res, result, 'Email OTP dispatched successfully.');
  } catch (err) {
    next(err);
  }
}

async function verifyEmailOTP(req, res, next) {
  try {
    const { email, otp } = req.body;
    await otpService.verifyOTP(email, otp);
    const authResult = await authService.authenticateEmail(email, req.ip);
    sendSuccess(res, authResult, 'Email authentication successful.');
  } catch (err) {
    next(err);
  }
}

async function requestMobileOTP(req, res, next) {
  try {
    const { phone } = req.body;
    const result = await otpService.generateAndSendOTP(phone, 'mobile');
    sendSuccess(res, result, 'Mobile SMS OTP dispatched successfully.');
  } catch (err) {
    next(err);
  }
}

async function verifyMobileOTP(req, res, next) {
  try {
    const { phone, otp } = req.body;
    await otpService.verifyOTP(phone, otp);
    const authResult = await authService.authenticateMobile(phone, req.ip);
    sendSuccess(res, authResult, 'Mobile authentication successful.');
  } catch (err) {
    next(err);
  }
}

async function googleSignIn(req, res, next) {
  try {
    const { idToken } = req.body;
    const authResult = await authService.authenticateGoogle(idToken, req.ip);
    sendSuccess(res, authResult, 'Google Sign-In authentication successful.');
  } catch (err) {
    next(err);
  }
}

async function registerInitiate(req, res, next) {
  try {
    const { email, username } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();
    if (!cleanEmail || !cleanEmail.includes('@')) {
      return sendError(res, 'Please provide a valid email address.', 'INVALID_EMAIL', 400);
    }
    const result = await otpService.generateAndSendOTP(cleanEmail, 'email');
    sendSuccess(res, result, `6-digit verification code sent to ${cleanEmail}`);
  } catch (err) {
    next(err);
  }
}

async function registerVerify(req, res, next) {
  try {
    const { email, otp, referralCode } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();
    await otpService.verifyOTP(cleanEmail, otp);
    const authResult = await authService.authenticateEmail(cleanEmail, req.ip, referralCode);
    sendSuccess(res, authResult, 'Account created and verified successfully!');
  } catch (err) {
    next(err);
  }
}

async function loginInitiate(req, res, next) {
  try {
    const { email, identifier } = req.body;
    const cleanEmail = (email || identifier || '').trim().toLowerCase();
    if (!cleanEmail || !cleanEmail.includes('@')) {
      return sendError(res, 'Please provide your registered email address.', 'INVALID_EMAIL', 400);
    }
    const result = await otpService.generateAndSendOTP(cleanEmail, 'email');
    sendSuccess(res, { ...result, requiresOtp: true, email: cleanEmail }, `Verification code sent to ${cleanEmail}`);
  } catch (err) {
    next(err);
  }
}

async function loginVerify(req, res, next) {
  try {
    const { email, identifier, otp } = req.body;
    const cleanEmail = (email || identifier || '').trim().toLowerCase();
    await otpService.verifyOTP(cleanEmail, otp);
    const authResult = await authService.authenticateEmail(cleanEmail, req.ip);
    sendSuccess(res, authResult, 'Login successful.');
  } catch (err) {
    next(err);
  }
}

async function resendOtp(req, res, next) {
  try {
    const { email } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();
    if (!cleanEmail || !cleanEmail.includes('@')) {
      return sendError(res, 'Please provide a valid email address.', 'INVALID_EMAIL', 400);
    }
    const result = await otpService.generateAndSendOTP(cleanEmail, 'email');
    sendSuccess(res, result, `New verification code sent to ${cleanEmail}`);
  } catch (err) {
    next(err);
  }
}

async function forgotPasswordInitiate(req, res, next) {
  try {
    const { email } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();
    if (!cleanEmail || !cleanEmail.includes('@')) {
      return sendError(res, 'Please provide a valid email address.', 'INVALID_EMAIL', 400);
    }
    const result = await otpService.generateAndSendOTP(cleanEmail, 'email');
    sendSuccess(res, result, `Password reset code sent to ${cleanEmail}`);
  } catch (err) {
    next(err);
  }
}

async function forgotPasswordVerifyOtp(req, res, next) {
  try {
    const { email, otp } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();
    await otpService.verifyOTP(cleanEmail, otp);
    const resetToken = jwt.sign(
      { email: cleanEmail, purpose: 'password_reset' },
      config.jwt.secret || 'dev_fallback_secret',
      { expiresIn: '1h' }
    );
    sendSuccess(res, { resetToken }, 'OTP verified successfully.');
  } catch (err) {
    next(err);
  }
}

async function forgotPasswordReset(req, res, next) {
  try {
    const { email, resetToken, newPassword, confirmPassword } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();
    if (!newPassword || newPassword.length < 6) {
      return sendError(res, 'Password must be at least 6 characters long.', 'VALIDATION_ERROR', 400);
    }
    if (newPassword !== confirmPassword) {
      return sendError(res, 'Passwords do not match.', 'VALIDATION_ERROR', 400);
    }
    if (resetToken) {
      try {
        const decoded = jwt.verify(resetToken, config.jwt.secret || 'dev_fallback_secret');
        if (decoded.purpose !== 'password_reset' || (decoded.email || '').toLowerCase() !== cleanEmail) {
          return sendError(res, 'Invalid or expired password reset session.', 'INVALID_TOKEN', 400);
        }
      } catch (_) {
        return sendError(res, 'Invalid or expired password reset token.', 'INVALID_TOKEN', 400);
      }
    }
    sendSuccess(res, { success: true }, 'Password reset successfully. You can now login with your new password.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  verifyMsg91Token,
  requestEmailOTP,
  verifyEmailOTP,
  requestMobileOTP,
  verifyMobileOTP,
  googleSignIn,
  registerInitiate,
  registerVerify,
  loginInitiate,
  loginVerify,
  resendOtp,
  forgotPasswordInitiate,
  forgotPasswordVerifyOtp,
  forgotPasswordReset,
};
