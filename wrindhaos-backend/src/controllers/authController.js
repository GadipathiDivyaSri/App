const msg91Service = require('../services/msg91Service');
const otpService = require('../services/otpService');
const authService = require('../services/authService');
const otpService = require('../services/otpService');
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

module.exports = {
  verifyMsg91Token,
  requestEmailOTP,
  verifyEmailOTP,
  requestMobileOTP,
  verifyMobileOTP,
  googleSignIn,
};
