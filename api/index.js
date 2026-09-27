let handleApiRequest;
try {
  handleApiRequest = require('../backend/api_handler').handleApiRequest || require('../backend/api_handler');
} catch (e1) {
  try {
    handleApiRequest = require('./api_handler').handleApiRequest || require('./api_handler');
  } catch (e2) {
    handleApiRequest = require('../api_handler').handleApiRequest || require('../api_handler');
  }
}

module.exports = async (req, res) => {
  try {
    const rawUrl = req.url || '/';
    if (rawUrl === '/' || rawUrl.includes('/api/index') || rawUrl.includes('/api/[...path]')) {
      if (req.headers['x-forwarded-uri'] && req.headers['x-forwarded-uri'].startsWith('/api')) {
        req.url = req.headers['x-forwarded-uri'];
      } else if (req.headers['x-matched-path'] && req.headers['x-matched-path'].startsWith('/api')) {
        req.url = req.headers['x-matched-path'];
      } else if (req.headers['x-invoke-path'] && req.headers['x-invoke-path'].startsWith('/api') && !req.headers['x-invoke-path'].includes('index') && !req.headers['x-invoke-path'].includes('[...path]')) {
        req.url = req.headers['x-invoke-path'];
      } else if (req.query && req.query.path) {
        const p = Array.isArray(req.query.path) ? req.query.path.join('/') : req.query.path;
        req.url = '/api/' + p.replace(/^\/+/, '');
      }
    }
    return await handleApiRequest(req, res);
  } catch (err) {
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ success: false, error: err.message, stack: err.stack }));
  }
};
