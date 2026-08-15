const { sendError } = require('../utils/response');

function validateBody(requiredFields) {
  return (req, res, next) => {
    const missing = [];
    for (const field of requiredFields) {
      if (req.body[field] === undefined || req.body[field] === null || req.body[field] === '') {
        missing.push(field);
      }
    }

    if (missing.length > 0) {
      return sendError(
        res,
        `Missing required request parameters: ${missing.join(', ')}`,
        'INVALID_REQUEST_PAYLOAD',
        400
      );
    }
    next();
  };
}

module.exports = {
  validateBody,
};
