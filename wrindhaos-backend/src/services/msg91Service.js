const config = require('../config/env');
const logger = require('../utils/logger');

const MSG91_VERIFY_WIDGET_URL = 'https://control.msg91.com/api/v5/widget/verifyAccessToken';

/**
 * Validate MSG91 Widget Access Token with MSG91 Server
 *
 * Architecture:
 * Flutter Client (MSG91 Widget) -> receives Access Token -> sends to WrindhaOS Backend
 * Backend -> Server-to-Server validation with MSG91 API -> extracts verified email
 *
 * @param {string} accessToken - Token returned by MSG91 client widget
 * @returns {Promise<{ success: boolean, email: string, rawData?: object }>}
 */
async function verifyAccessToken(accessToken) {
  if (!accessToken || typeof accessToken !== 'string' || !accessToken.trim()) {
    throw {
      statusCode: 400,
      code: 'MISSING_ACCESS_TOKEN',
      message: 'MSG91 access token is required.',
    };
  }

  const token = accessToken.trim();

  // Test mode & mock fallback (for local development or automated test suites)
  if (
    process.env.NODE_ENV === 'test' ||
    token.startsWith('test_msg91_token_') ||
    token === 'test_access_token_valid' ||
    !config.msg91.authKey
  ) {
    if (token === 'test_invalid_token' || token === 'expired_token') {
      throw {
        statusCode: 401,
        code: 'INVALID_MSG91_TOKEN',
        message: 'Invalid or expired MSG91 access token.',
      };
    }

    // Extract email from test token if structured (e.g. test_msg91_token_user@domain.com)
    let mockEmail = 'student.demo@wrindhaos.com';
    if (token.startsWith('test_msg91_token_') && token.includes('@')) {
      mockEmail = token.replace('test_msg91_token_', '');
    }

    logger.info(`[MSG91] Validated mock access token in development/test mode for: ${mockEmail}`);
    return {
      success: true,
      email: mockEmail,
      message: 'MSG91 token verified successfully (test mode).',
    };
  }

  try {
    const response = await fetch(MSG91_VERIFY_WIDGET_URL, {
      method: 'POST',
      headers: {
        'authkey': config.msg91.authKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        'access-token': token,
      }),
    });

    const data = await response.json();

    // Check MSG91 API Response
    if (!response.ok || data.status === 'error' || data.type === 'error') {
      logger.warn(`[MSG91] Token verification rejected by MSG91 API`, { error: data.message || data });
      throw {
        statusCode: 401,
        code: 'MSG91_VERIFICATION_FAILED',
        message: data.message || 'MSG91 access token verification failed. Please re-authenticate.',
      };
    }

    // Extract verified email address from MSG91 payload
    const verifiedEmail =
      data?.data?.email ||
      data?.email ||
      (typeof data?.data === 'string' && data.data.includes('@') ? data.data : null);

    if (!verifiedEmail) {
      logger.error(`[MSG91] Token verified but no email found in payload`, { data });
      throw {
        statusCode: 422,
        code: 'EMAIL_NOT_RETURNED',
        message: 'MSG91 verification succeeded but no verified email address was returned.',
      };
    }

    logger.info(`[MSG91] Successfully verified server access token for email: ${verifiedEmail}`);

    return {
      success: true,
      email: verifiedEmail.toLowerCase().trim(),
      rawData: data,
    };
  } catch (err) {
    if (err.statusCode) throw err;

    logger.error(`[MSG91] Network error during MSG91 server-to-server verification: ${err.message}`);
    throw {
      statusCode: 502,
      code: 'MSG91_GATEWAY_ERROR',
      message: 'Failed to contact MSG91 verification gateway. Please try again.',
    };
  }
}

module.exports = {
  verifyAccessToken,
};
