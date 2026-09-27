const { handleApiRequest } = require("../backend/api_handler");

module.exports = async (req, res) => {
  try {
    if (req.headers['x-invoke-path'] && req.headers['x-invoke-path'].startsWith('/api')) {
      req.url = req.headers['x-invoke-path'];
    } else if (req.query && req.query.path) {
      const p = Array.isArray(req.query.path) ? req.query.path.join('/') : req.query.path;
      req.url = '/api/' + p.replace(/^\/+/, '');
    } else if (req.url && !req.url.startsWith('/api')) {
      req.url = '/api' + (req.url.startsWith('/') ? '' : '/') + req.url;
    }
    return await handleApiRequest(req, res);
  } catch (err) {
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ success: false, error: err.message, stack: err.stack }));
  }
};
