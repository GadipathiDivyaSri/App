const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { otpRateLimiter } = require('../middleware/rateLimitMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');

// Email OTP Endpoints
router.post('/email/request-otp', otpRateLimiter, validateBody(['email']), authController.requestEmailOTP);
router.post('/email/verify-otp', validateBody(['email', 'otp']), authController.verifyEmailOTP);

// Mobile OTP Endpoints
router.post('/mobile/request-otp', otpRateLimiter, validateBody(['phone']), authController.requestMobileOTP);
router.post('/mobile/verify-otp', validateBody(['phone', 'otp']), authController.verifyMobileOTP);

// Google Sign-In Endpoint
router.post('/google', validateBody(['idToken']), authController.googleSignIn);

module.exports = router;
