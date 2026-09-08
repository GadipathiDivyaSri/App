const { handleApiRequest } = require("../api_handler");

module.exports = async (req, res) => {
  return handleApiRequest(req, res);
};