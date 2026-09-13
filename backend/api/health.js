const { handleApiRequest } = require('../api_handler');

module.exports = async (req, res) => {
  req.url = '/api/health';
  return handleApiRequest(req, res);
};
