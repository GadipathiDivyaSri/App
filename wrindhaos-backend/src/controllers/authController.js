const authService = require('../services/authService');
const otpService = require('../services/otpService');
const { sendSuccess, sendError } = require('../utils/response');

async function checkUsername(req, res, next) {
  try {
    const { username } = req.body;
    const result = await authService.checkUsernameAvailability(username);
    sendSuccess(res, result, result.message || 'Username check completed.');
  } catch (err) {
    next(err);
  }
}

async function registerInitiate(req, res, next) {
  try {
    const { username, email, password, confirmPassword } = req.body;
    const result = await authService.registerInitiate({
      username,
      email,
      password,
      confirmPassword,
      ipAddress: req.ip,
    });
    sendSuccess(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

async function registerVerify(req, res, next) {
  try {
    const { email, code, referredByCode } = req.body;
    const result = await authService.registerVerify({
      email,
      code,
      ipAddress: req.ip,
      referredByCode,
    });
    sendSuccess(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

async function resendOTP(req, res, next) {
  try {
    const { email } = req.body;
    const result = await authService.resendOTP({ email, ipAddress: req.ip });
    sendSuccess(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const { username, password } = req.body;
    const result = await authService.login({ username, password, ipAddress: req.ip });
    sendSuccess(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

async function googleAuth(req, res, next) {
  try {
    const { email, name, googleId, idToken } = req.body;
    const result = await authService.googleAuth({
      email,
      name,
      googleId: googleId || idToken,
      ipAddress: req.ip,
    });
    sendSuccess(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

async function googleComplete(req, res, next) {
  try {
    const { email, name, googleId, username } = req.body;
    const result = await authService.googleComplete({
      email,
      name,
      googleId,
      username,
      ipAddress: req.ip,
    });
    sendSuccess(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

async function forgotPasswordInitiate(req, res, next) {
  try {
    const { identifier } = req.body;
    const result = await authService.forgotPasswordInitiate({ identifier, ipAddress: req.ip });
    sendSuccess(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

async function forgotPasswordVerify(req, res, next) {
  try {
    const { email, code } = req.body;
    const result = await authService.forgotPasswordVerify({ email, code, ipAddress: req.ip });
    sendSuccess(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

async function forgotPasswordReset(req, res, next) {
  try {
    const { email, code, newPassword, confirmPassword } = req.body;
    const result = await authService.forgotPasswordReset({
      email,
      code,
      newPassword,
      confirmPassword,
      ipAddress: req.ip,
    });
    sendSuccess(res, result, result.message);
  } catch (err) {
    next(err);
  }
}

async function validateSession(req, res, next) {
  try {
    const authHeader = req.headers['authorization'] || '';
    const token = authHeader.replace('Bearer ', '').trim();
    const result = await authService.validateSession(token);
    sendSuccess(res, result, result.message);
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
  checkUsername,
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
  requestEmailOTP,
  verifyEmailOTP,
  requestMobileOTP,
  verifyMobileOTP,
  googleSignIn,
};
