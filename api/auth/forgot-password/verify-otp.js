const { handleApiRequest } = require('../../../backend/api_handler');

module.exports = async (req, res) => {
  req.url = '/api/auth/forgot-password/verify-otp';
  return handleApiRequest(req, res);
};
