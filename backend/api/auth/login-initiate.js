const { handleApiRequest } = require('../../api_handler');

module.exports = async (req, res) => {
  req.url = '/api/auth/login-initiate';
  return handleApiRequest(req, res);
};
