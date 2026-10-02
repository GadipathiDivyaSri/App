const { handleApiRequest } = require('../backend/api_handler');

module.exports = async (req, res) => {
  const queryPart = req.url && req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : '';
  const pathPart = req.url ? req.url.split('?')[0] : '';

  if (!pathPart || pathPart === '/' || pathPart === '/subscription' || pathPart === '/api' || pathPart === '/api/subscription') {
    req.url = (req.method === 'POST' ? '/api/subscription/upgrade' : '/api/subscription/me') + queryPart;
  } else if (pathPart.startsWith('/subscription/')) {
    req.url = '/api' + pathPart + queryPart;
  } else if (!pathPart.startsWith('/api/subscription')) {
    req.url = '/api/subscription' + (pathPart.startsWith('/') ? pathPart : '/' + pathPart) + queryPart;
  }
  return handleApiRequest(req, res);
};
