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
// LEGACY COMPATIBILITY ENDPOINTS (Preserved temporarily for Flutter migration)
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

// Legacy Mobile OTP (Marked for removal in final cleanup)
router.post('/mobile/request-otp', otpRateLimiter, validateBody(['phone']), authController.requestMobileOTP);
router.post('/mobile/verify-otp', validateBody(['phone', 'otp']), authController.verifyMobileOTP);

// Legacy Google Sign-In (Marked for removal in final cleanup)
router.post('/google', validateBody(['idToken']), authController.googleSignIn);

module.exports = router;
