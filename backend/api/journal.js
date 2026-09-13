const { handleApiRequest } = require('../api_handler');

module.exports = async (req, res) => {
  if (!req.url || req.url === '/' || req.url === '/journal') {
    req.url = '/api/journal';
  }
  return handleApiRequest(req, res);
};
