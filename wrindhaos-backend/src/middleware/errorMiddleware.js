const logger = require('../utils/logger');
const { sendError } = require('../utils/response');

/**
 * Global Error Handler Middleware
 * Redacts stack traces and credentials in production.
 */
function globalErrorHandler(err, req, res, next) {
  logger.error('Unhandled application error', err, {
    path: req.originalUrl,
    method: req.method,
    ip: req.ip,
  });

  const statusCode = err.statusCode || 500;
  const errorCode = err.code || 'INTERNAL_SERVER_ERROR';
  const message = process.env.NODE_ENV === 'production' && statusCode === 500
    ? 'An internal server error occurred. Please try again later.'
    : err.message || 'An unknown error occurred.';

  sendError(res, message, errorCode, statusCode);
}

module.exports = {
  globalErrorHandler,
};
