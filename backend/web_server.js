const http = require('http');
const fs = require('fs');
const path = require('path');
const { handleApiRequest } = require('./api_handler');

const PORT = process.env.WEB_PORT || 8080;
const WEB_DIR = path.join(__dirname, '..', 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html; charset=UTF-8',
  '.js': 'application/javascript; charset=UTF-8',
  '.json': 'application/json; charset=UTF-8',
  '.css': 'text/css; charset=UTF-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

const server = http.createServer((req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    return res.end();
  }

  // 1. API Route Proxy/Handler directly on same port (http://localhost:8080/api/*)
  if (req.url.startsWith('/api/')) {
    return handleApiRequest(req, res);
  }

  // 2. Static Web App Files
  let cleanUrl = req.url.split('?')[0];
  if (cleanUrl.startsWith('/WRINDHA_OS_APP')) {
    cleanUrl = cleanUrl.replace(/^\/WRINDHA_OS_APP/, '') || '/';
  } else if (cleanUrl.startsWith('/App')) {
    cleanUrl = cleanUrl.replace(/^\/App/, '') || '/';
  }
  if (cleanUrl === '/' || cleanUrl === '') cleanUrl = '/index.html';

  let filePath = path.join(WEB_DIR, cleanUrl);

  // If specific file exists, serve it
  if (fs.existsSync(filePath) && !fs.statSync(filePath).isDirectory()) {
    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, content) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        return res.end(`Server Error: ${err.message}`);
      }
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content);
    });
    return;
  }

  // Fallback to index.html for Single Page Application
  const indexPath = path.join(WEB_DIR, 'index.html');
  fs.readFile(indexPath, (err, content) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      return res.end(`Server Error loading index.html: ${err.message}`);
    }
    res.writeHead(200, { 'Content-Type': 'text/html; charset=UTF-8' });
    res.end(content);
  });
});

server.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(`🌐 WrindhaOS App + Backend running at: http://localhost:${PORT}`);
  console.log(`📡 API Health: http://localhost:${PORT}/api/health`);
  console.log(`=======================================================`);
});
