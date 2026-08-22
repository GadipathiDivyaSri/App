const http = require('http');
const { handleApiRequest } = require('./api_handler');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  handleApiRequest(req, res);
});

server.listen(PORT, () => {
  console.log(`===================================================`);
  console.log(`🚀 Wrindha OS Backend Service running on port ${PORT}`);
  console.log(`📡 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`===================================================`);
});
