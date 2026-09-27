let handleApiRequest;
try {
  handleApiRequest = require('../api_handler').handleApiRequest;
} catch (e1) {
  try {
    handleApiRequest = require('../../backend/api_handler').handleApiRequest;
  } catch (e2) {
    handleApiRequest = require('./api_handler').handleApiRequest;
  }
}

module.exports = async (req, res) => {
  try {
    return await handleApiRequest(req, res);
  } catch (err) {
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ success: false, error: err.message, stack: err.stack }));
  }
};
