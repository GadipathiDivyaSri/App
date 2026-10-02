const { handleApiRequest } = require('../backend/api_handler');

module.exports = async (req, res) => {
  const queryPart = req.url && req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : '';
  req.url = '/api/subscription/upgrade' + queryPart;
  return handleApiRequest(req, res);
};
