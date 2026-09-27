const { handleApiRequest } = require('../backend/api_handler');

module.exports = async (req, res) => {
  req.url = '/api/auth/register-initiate';
  return handleApiRequest(req, res);
};
