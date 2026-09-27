let handleApiRequest;
try {
  const mod = require("../../../api_handler");
  handleApiRequest = mod.handleApiRequest || mod;
} catch (e1) {
  try {
    const mod = require("../../../backend/api_handler");
    handleApiRequest = mod.handleApiRequest || mod;
  } catch (e2) {
    const mod = require("../../api_handler");
    handleApiRequest = mod.handleApiRequest || mod;
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
