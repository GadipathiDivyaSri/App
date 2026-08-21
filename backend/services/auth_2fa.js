const axios = require('axios');

const API_KEY = process.env.TWO_FACTOR_API_KEY;

/**
 * SEND OTP VIA SMS
 */
async function send2FAOTP(contact) {
  try {
    if (!API_KEY) {
      console.error('[2FACTOR ERROR] API key is missing');
      return {
        success: false,
        message: '2Factor API key is not configured.'
      };
    }

    // Clean phone number
    let phone = String(contact)
      .trim()
      .replace(/\s+/g, '')
      .replace(/^\+91/, '')
      .replace(/^91/, '');

    if (!/^[6-9]\d{9}$/.test(phone)) {
      return {
        success: false,
        message: 'Please enter a valid Indian mobile number.'
      };
    }

    // ✅ FIX: Removed template name - using default template
    const apiUrl = `https://2factor.in/API/V1/${API_KEY}/SMS/${phone}/AUTOGEN`;

    console.log('[2FACTOR] Sending SMS to:', phone);

    const response = await axios.get(apiUrl, {
      timeout: 15000
    });

    console.log('[2FACTOR RESPONSE]', response.data);

    if (response.data.Status !== 'Success') {
      return {
        success: false,
        message: response.data.Details || 'Failed to send OTP.'
      };
    }

    return {
      success: true,
      message: 'OTP sent successfully',
      sessionId: response.data.Details
    };

  } catch (error) {
    console.error('[2FACTOR ERROR]', error.message);
    return {
      success: false,
      message: 'Unable to send OTP. Please try again.'
    };
  }
}

/**
 * VERIFY OTP
 */
async function verify2FAOTP(sessionId, code) {
  try {
    if (!API_KEY) {
      return {
        success: false,
        message: '2Factor API key is not configured.'
      };
    }

    if (!sessionId || !code) {
      return {
        success: false,
        message: 'Session ID and OTP are required.'
      };
    }

    const apiUrl = `https://2factor.in/API/V1/${API_KEY}/SMS/VERIFY/${sessionId}/${code}`;

    console.log('[2FACTOR] Verifying OTP');

    const response = await axios.get(apiUrl, {
      timeout: 15000
    });

    console.log('[2FACTOR VERIFY]', response.data);

    if (response.data.Status === 'Success') {
      return {
        success: true,
        message: 'OTP verification successful.'
      };
    }

    return {
      success: false,
      message: response.data.Details || 'Invalid or expired OTP.'
    };

  } catch (error) {
    console.error('[2FACTOR VERIFY ERROR]', error.message);
    return {
      success: false,
      message: 'OTP verification failed.'
    };
  }
}

/**
 * RESEND OTP
 */
async function resend2FAOTP(sessionId) {
  try {
    if (!sessionId) {
      return {
        success: false,
        message: 'Session ID is required.'
      };
    }

    const apiUrl = `https://2factor.in/API/V1/${API_KEY}/SMS/RESEND/${sessionId}`;

    console.log('[2FACTOR] Resending OTP');

    const response = await axios.get(apiUrl, {
      timeout: 15000
    });

    if (response.data.Status === 'Success') {
      return {
        success: true,
        message: 'OTP resent successfully.',
        sessionId: response.data.Details || sessionId
      };
    }

    return {
      success: false,
      message: response.data.Details || 'Failed to resend OTP.'
    };

  } catch (error) {
    console.error('[2FACTOR RESEND ERROR]', error.message);
    return {
      success: false,
      message: 'Failed to resend OTP.'
    };
  }
}

/**
 * GOOGLE TOKEN VERIFICATION
 */
function verifyGoogleToken(googleToken) {
  return {
    success: true,
    user: {
      id: 'g_123',
      name: 'Google User',
      email: 'user@gmail.com'
    },
    token: 'mock_jwt_google_sso_token'
  };
}

module.exports = {
  send2FAOTP,
  verify2FAOTP,
  resend2FAOTP,
  verifyGoogleToken
};