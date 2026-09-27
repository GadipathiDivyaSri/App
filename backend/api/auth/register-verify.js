const { handleApiRequest } = require('../../api_handler');

module.exports = async (req, res) => {
  req.url = '/api/auth/register-verify';
  return handleApiRequest(req, res);
};
