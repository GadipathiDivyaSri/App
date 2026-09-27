const path = require('path');
const { handleApiRequest } = require(path.join(process.cwd(), 'backend', 'api_handler'));

module.exports = async (req, res) => {
  try {
    return await handleApiRequest(req, res);
  } catch (err) {
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ success: false, error: err.message, stack: err.stack }));
  }
};
