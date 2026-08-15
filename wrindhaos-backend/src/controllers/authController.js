const otpService = require('../services/otpService');
const authService = require('../services/authService');
const { sendSuccess, sendError } = require('../utils/response');

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
  requestEmailOTP,
  verifyEmailOTP,
  requestMobileOTP,
  verifyMobileOTP,
  googleSignIn,
};
