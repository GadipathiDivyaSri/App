const { handleApiRequest } = require('../../api_handler');

module.exports = async (req, res) => {
  req.url = '/api/auth/refresh-token';
  return handleApiRequest(req, res);
};
