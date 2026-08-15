/**
 * Standardized Success API Response Helper
 */
function sendSuccess(res, data = {}, message = 'Operation successful', statusCode = 200) {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
}

/**
 * Standardized Error API Response Helper
 */
function sendError(res, message = 'An error occurred', code = 'INTERNAL_ERROR', statusCode = 500) {
  return res.status(statusCode).json({
    success: false,
    error: {
      code,
      message,
    },
  });
}

module.exports = {
  sendSuccess,
  sendError,
};
