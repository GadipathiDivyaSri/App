const app = require('./src/app');
const config = require('./src/config/env');
const logger = require('./src/utils/logger');

const server = app.listen(config.port, () => {
  console.log(`===========================================================`);
  console.log(`🚀 WrindhaOS Production Backend running on port ${config.port}`);
  console.log(`📡 Health Check: http://localhost:${config.port}/health`);
  console.log(`📄 API Swagger Docs: http://localhost:${config.port}/api-docs`);
  console.log(`🔐 Auth: Email OTP | Mobile OTP | Google SSO`);
  console.log(`💳 Payments: Google Play Billing Server-Side Verification ONLY`);
  console.log(`===========================================================`);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received. Closing HTTP server gracefully.');
  server.close(() => {
    logger.info('HTTP server closed.');
    process.exit(0);
  });
});
