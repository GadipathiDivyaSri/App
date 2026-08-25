const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');

// Load .env file from local directory first, then parent directory fallback
const localEnvPath = path.resolve(__dirname, '../../.env');
const rootEnvPath = path.resolve(__dirname, '../../../../.env');

if (fs.existsSync(localEnvPath)) {
  dotenv.config({ path: localEnvPath });
} else if (fs.existsSync(rootEnvPath)) {
  dotenv.config({ path: rootEnvPath });
} else {
  dotenv.config();
}

const isProduction = (process.env.NODE_ENV === 'production');

// Fail loudly in production if critical secrets are missing
if (isProduction) {
  const requiredProductionKeys = ['JWT_SECRET', 'SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];
  const missingKeys = requiredProductionKeys.filter((key) => !process.env[key]);
  if (missingKeys.length > 0) {
    console.error(`[FATAL] Missing required production environment variables: ${missingKeys.join(', ')}`);
    console.error(`[FATAL] Please configure these in your production environment or .env file.`);
  }
}

const config = {
  port: parseInt(process.env.PORT || '5000', 10),
  env: process.env.NODE_ENV || 'development',
  isProduction,

  supabase: {
    url: process.env.SUPABASE_URL || '',
    anonKey: process.env.SUPABASE_ANON_KEY || '',
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  },

  jwt: {
    secret: process.env.JWT_SECRET || (isProduction ? '' : 'dev_jwt_secret_change_in_production'),
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  },

  msg91: {
    authKey: process.env.MSG91_AUTH_KEY || '',
    widgetId: process.env.MSG91_WIDGET_ID || '',
    templateId: process.env.MSG91_OTP_TEMPLATE_ID || '',
    otpExpiryMinutes: parseInt(process.env.MSG91_OTP_EXPIRY_MINUTES || '5', 10),
  },

  otp: {
    provider: process.env.OTP_PROVIDER || 'msg91',
    apiKey: process.env.MSG91_AUTH_KEY || process.env.OTP_API_KEY || '',
    templateId: process.env.MSG91_OTP_TEMPLATE_ID || process.env.OTP_TEMPLATE_ID || '',
  },

  googlePlay: {
    packageName: process.env.GOOGLE_PLAY_PACKAGE_NAME || 'com.wrindhaos.app',
    serviceAccountEmail: process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL || '',
    privateKey: (process.env.GOOGLE_PLAY_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    subscriptionProductId: process.env.GOOGLE_PLAY_SUBSCRIPTION_PRODUCT_ID || 'wrindhaos_premium_monthly',
  },

  fcm: {
    projectId: process.env.FCM_PROJECT_ID || '',
    clientEmail: process.env.FCM_CLIENT_EMAIL || '',
    privateKey: (process.env.FCM_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  },

  frontendUrl: process.env.FRONTEND_URL || 'http://localhost:8080',
};

module.exports = config;
