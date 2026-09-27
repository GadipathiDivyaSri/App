const { handleApiRequest } = require('../api_handler');

module.exports = async (req, res) => {
  req.url = '/api/account/delete';
  return handleApiRequest(req, res);
};
