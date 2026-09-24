const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { otpRateLimiter } = require('../middleware/rateLimitMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');

// =============================================================================
// PRIMARY AUTHENTICATION ROUTE: MSG91 Email OTP Server Verification
// =============================================================================
router.post('/msg91/verify', otpRateLimiter, validateBody(['accessToken']), authController.verifyMsg91Token);
router.post('/email/verify-token', otpRateLimiter, validateBody(['accessToken']), authController.verifyMsg91Token);

// =============================================================================
// FLUTTER AUTHENTICATION & PASSWORD RESET ENDPOINTS
// =============================================================================
router.post('/register-initiate', otpRateLimiter, validateBody(['email']), authController.registerInitiate);
router.post('/register-verify', validateBody(['email', 'otp']), authController.registerVerify);
router.post('/login-initiate', otpRateLimiter, validateBody(['email']), authController.loginInitiate);
router.post('/login-verify', validateBody(['email', 'otp']), authController.loginVerify);
router.post('/resend-otp', otpRateLimiter, validateBody(['email']), authController.resendOtp);

router.post('/forgot-password/initiate', otpRateLimiter, validateBody(['email']), authController.forgotPasswordInitiate);
router.post('/forgot-password/verify-otp', validateBody(['email', 'otp']), authController.forgotPasswordVerifyOtp);
router.post('/forgot-password/reset', validateBody(['email', 'newPassword']), authController.forgotPasswordReset);

// Aliases for legacy/alternative routes
router.post('/forgot-password/verify', validateBody(['email', 'otp']), authController.forgotPasswordVerifyOtp);
router.post('/reset-password', validateBody(['email', 'newPassword']), authController.forgotPasswordReset);
router.post('/reset', validateBody(['email', 'newPassword']), authController.forgotPasswordReset);

// =============================================================================
// LEGACY COMPATIBILITY ENDPOINTS
// =============================================================================
router.post('/send-otp', otpRateLimiter, (req, res, next) => {
  if (req.body.email) return authController.requestEmailOTP(req, res, next);
  if (req.body.contact && req.body.contact.includes('@')) {
    req.body.email = req.body.contact;
    return authController.requestEmailOTP(req, res, next);
  }
  return authController.requestMobileOTP(req, res, next);
});

router.post('/verify-otp', (req, res, next) => {
  if (req.body.accessToken) return authController.verifyMsg91Token(req, res, next);
  if (req.body.email && req.body.otp) return authController.verifyEmailOTP(req, res, next);
  if (req.body.contact && req.body.code) {
    if (req.body.contact.includes('@')) {
      req.body.email = req.body.contact;
      req.body.otp = req.body.code;
      return authController.verifyEmailOTP(req, res, next);
    }
    req.body.phone = req.body.contact;
    req.body.otp = req.body.code;
    return authController.verifyMobileOTP(req, res, next);
  }
  return authController.verifyEmailOTP(req, res, next);
});

// Legacy direct email OTP
router.post('/email/request-otp', otpRateLimiter, validateBody(['email']), authController.requestEmailOTP);
router.post('/email/verify-otp', validateBody(['email', 'otp']), authController.verifyEmailOTP);

// Legacy Mobile OTP
router.post('/mobile/request-otp', otpRateLimiter, validateBody(['phone']), authController.requestMobileOTP);
router.post('/mobile/verify-otp', validateBody(['phone', 'otp']), authController.verifyMobileOTP);

// Legacy Google Sign-In
router.post('/google', validateBody(['idToken']), authController.googleSignIn);

module.exports = router;
