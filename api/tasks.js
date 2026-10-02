const { handleApiRequest } = require('../backend/api_handler');

module.exports = async (req, res) => {
  const queryPart = req.url && req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : '';
  const pathPart = req.url ? req.url.split('?')[0] : '';

  if (!pathPart || pathPart === '/' || pathPart === '/tasks' || pathPart === '/api' || pathPart === '/api/tasks') {
    req.url = '/api/tasks' + queryPart;
  } else if (pathPart.startsWith('/tasks/')) {
    req.url = '/api' + pathPart + queryPart;
  } else if (!pathPart.startsWith('/api/tasks')) {
    req.url = '/api/tasks' + (pathPart.startsWith('/') ? pathPart : '/' + pathPart) + queryPart;
  }
  return handleApiRequest(req, res);
};
