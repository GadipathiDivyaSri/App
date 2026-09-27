const { handleApiRequest } = require("../../api_handler");

module.exports = async (req, res) => {
  if (req.url && !req.url.startsWith('/api')) {
    req.url = '/api' + (req.url.startsWith('/') ? '' : '/') + req.url;
  }
  return handleApiRequest(req, res);
};
