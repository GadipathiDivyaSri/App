const { handleApiRequest } = require('../backend/api_handler');
const url = require('url');

module.exports = async (req, res) => {
  try {
    const parsed = url.parse(req.url || '/', true);
    req.url = '/api/auth/login-initiate';
    res.setHeader('X-Debug-Req-Url', req.url);
    res.setHeader('X-Debug-Method', req.method || 'UNKNOWN');
    res.setHeader('X-Debug-Forwarded-Uri', req.headers['x-forwarded-uri'] || 'NONE');
    return await handleApiRequest(req, res);
  } catch (err) {
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ success: false, error: err.message, stack: err.stack }));
  }
};
