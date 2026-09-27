const { handleApiRequest } = require("../api_handler");

module.exports = async (req, res) => {
  if (req.headers['x-invoke-path'] && req.headers['x-invoke-path'] !== '/api/[...path]') {
    req.url = req.headers['x-invoke-path'];
  } else if (req.query && req.query.path) {
    const p = Array.isArray(req.query.path) ? req.query.path.join('/') : req.query.path;
    req.url = '/api/' + p.replace(/^\/+/, '');
  } else if (req.url && !req.url.startsWith('/api')) {
    req.url = '/api' + (req.url.startsWith('/') ? '' : '/') + req.url;
  }
  return handleApiRequest(req, res);
};
