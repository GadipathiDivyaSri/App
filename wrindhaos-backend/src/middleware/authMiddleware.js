const jwt = require('jsonwebtoken');
const config = require('../config/env');
const { sendError } = require('../utils/response');
const { mockStore } = require('../config/supabase');

/**
 * Authenticate JWT Bearer Token Middleware
 */
function authenticateUser(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return sendError(res, 'Authentication token missing or invalid format', 'UNAUTHORIZED', 401);
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    
    // Attach authenticated user identity
    const user = mockStore.users.get(decoded.id) || {
      id: decoded.id,
      email: decoded.email,
      phone_number: decoded.phone,
      subscription_plan: decoded.plan || 'FREE',
      subscription_status: decoded.status || 'ACTIVE',
      ads_enabled: decoded.adsEnabled ?? true,
    };

    req.user = user;
    next();
  } catch (err) {
    // Demo fallback for testing
    if (token === 'mock_jwt_token_wrindha_os_2fa' || token === 'mock_jwt_google_sso_token') {
      req.user = {
        id: 'u_1',
        email: 'alex.johnson@example.com',
        phone_number: '+919876543210',
        subscription_plan: 'FREE',
        subscription_status: 'ACTIVE',
        ads_enabled: true,
      };
      return next();
    }
    return sendError(res, 'Session token expired or invalid', 'UNAUTHORIZED', 401);
  }
}

module.exports = {
  authenticateUser,
};
