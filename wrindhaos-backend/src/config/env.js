const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const config = {
  port: process.env.PORT || 5000,
  env: process.env.NODE_ENV || 'development',

  supabase: {
    url: process.env.SUPABASE_URL || 'https://xyzproductivedb.supabase.co',
    anonKey: process.env.SUPABASE_ANON_KEY || 'mock_anon_key',
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || 'mock_service_role_key',
  },

  jwt: {
    secret: process.env.JWT_SECRET || 'wrindhaos_super_secret_jwt_key_2026',
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  },

  google: {
    clientId: process.env.GOOGLE_CLIENT_ID || 'mock_google_client_id',
  },

  googlePlay: {
    packageName: process.env.GOOGLE_PLAY_PACKAGE_NAME || 'com.wrindhaos.app',
    serviceAccountEmail: process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL || 'wrindhaos-billing@project.iam.gserviceaccount.com',
    privateKey: (process.env.GOOGLE_PLAY_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    subscriptionProductId: process.env.GOOGLE_PLAY_SUBSCRIPTION_PRODUCT_ID || 'wrindhaos_premium_monthly',
  },

  otp: {
    provider: process.env.OTP_PROVIDER || 'twilio',
    apiKey: process.env.OTP_API_KEY || 'mock_otp_api_key',
    templateId: process.env.OTP_TEMPLATE_ID || 'mock_otp_template',
  },

  fcm: {
    projectId: process.env.FCM_PROJECT_ID || 'wrindhaos-firebase',
    clientEmail: process.env.FCM_CLIENT_EMAIL || 'firebase@wrindhaos.iam.gserviceaccount.com',
    privateKey: (process.env.FCM_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  },

  frontendUrl: process.env.FRONTEND_URL || 'http://localhost:8080',
};

module.exports = config;
