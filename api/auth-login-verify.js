const { handleApiRequest } = require('../backend/api_handler');

module.exports = async (req, res) => {
  req.url = '/api/auth/login-verify';
  return handleApiRequest(req, res);
};
