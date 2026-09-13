const { handleApiRequest } = require("../backend/api_handler");

module.exports = async (req, res) => {
  return handleApiRequest(req, res);
};
