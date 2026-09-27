const { handleApiRequest } = require('../../api_handler');

module.exports = async (req, res) => {
  req.url = '/api/users/me';
  return handleApiRequest(req, res);
};
