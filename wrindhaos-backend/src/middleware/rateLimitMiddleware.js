const rateLimit = require('express-rate-limit');
const { sendError } = require('../utils/response');

// Strict Rate Limiter for OTP Requests (Prevents OTP abuse & SMS flooding)
const otpRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Maximum 5 OTP requests per IP per window
  handler: (req, res) => {
    sendError(res, 'Too many OTP requests from this device. Please wait 15 minutes before trying again.', 'TOO_MANY_REQUESTS', 429);
  },
});

// Rate Limiter for Subscription & Google Play Verification
const subscriptionRateLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: 10,
  handler: (req, res) => {
    sendError(res, 'Too many subscription verification attempts. Please wait.', 'TOO_MANY_REQUESTS', 429);
  },
});

// General API Rate Limiter
const generalRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 120, // 120 requests per minute
  handler: (req, res) => {
    sendError(res, 'API rate limit exceeded. Please slow down your requests.', 'TOO_MANY_REQUESTS', 429);
  },
});

module.exports = {
  otpRateLimiter,
  subscriptionRateLimiter,
  generalRateLimiter,
};
