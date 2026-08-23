const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { otpRateLimiter } = require('../middleware/rateLimitMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');

// 1. Username Availability Check
router.post('/check-username', validateBody(['username']), authController.checkUsername);

// 2. Create Account Flow (Step 1: Validate & Send OTP, Step 2: Verify & Create)
router.post('/register-initiate', otpRateLimiter, validateBody(['username', 'email', 'password']), authController.registerInitiate);
router.post('/register-verify', validateBody(['email', 'code']), authController.registerVerify);
router.post('/resend-otp', otpRateLimiter, validateBody(['email']), authController.resendOTP);

// 3. Login Flow (Username + Password)
router.post('/login', validateBody(['username', 'password']), authController.login);

// 4. Continue with Google Flow
router.post('/google', authController.googleAuth);
router.post('/google-complete', validateBody(['email', 'username']), authController.googleComplete);

// 5. Forgot Password Flow
router.post('/forgot-password/initiate', otpRateLimiter, validateBody(['identifier']), authController.forgotPasswordInitiate);
router.post('/forgot-password/verify', validateBody(['email', 'code']), authController.forgotPasswordVerify);
router.post('/forgot-password/reset', validateBody(['email', 'code', 'newPassword']), authController.forgotPasswordReset);

// 6. Session Validation
router.get('/session', authController.validateSession);

// 7. Legacy OTP & Google Helpers
router.post('/email/request-otp', otpRateLimiter, validateBody(['email']), authController.requestEmailOTP);
router.post('/email/verify-otp', validateBody(['email', 'otp']), authController.verifyEmailOTP);
router.post('/mobile/request-otp', otpRateLimiter, validateBody(['phone']), authController.requestMobileOTP);
router.post('/mobile/verify-otp', validateBody(['phone', 'otp']), authController.verifyMobileOTP);
router.post('/google-signin', validateBody(['idToken']), authController.googleSignIn);

module.exports = router;
