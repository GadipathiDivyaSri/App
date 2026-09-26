const { handleApiRequest } = require('../backend/api_handler');

module.exports = async (req, res) => {
  if (req.headers['x-invoke-path'] && req.headers['x-invoke-path'].startsWith('/api')) {
    req.url = req.headers['x-invoke-path'];
  } else if (!req.url.startsWith('/api')) {
    req.url = '/api' + (req.url.startsWith('/') ? '' : '/') + req.url;
  }
  return handleApiRequest(req, res);
};
