const http = require('http');
const fs = require('fs');
const path = require('path');
const { handleApiRequest } = require('./backend/api_handler');

const dir = __dirname;

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ttf': 'application/font-ttf',
  '.otf': 'application/font-otf',
  '.woff': 'application/font-woff',
  '.woff2': 'font/woff2',
  '.wasm': 'application/wasm',
};

function createServer() {
  return http.createServer((req, res) => {
    // 1. Route API requests to backend handler
    if (req.url.startsWith('/api/') || req.url === '/api') {
      return handleApiRequest(req, res);
    }

    // 2. Serve static frontend files
    let reqUrl = req.url.split('?')[0];
    if (reqUrl.startsWith('/App/')) {
      reqUrl = reqUrl.substring(4);
    } else if (reqUrl.startsWith('/App')) {
      reqUrl = reqUrl.substring(4) || '/';
    }

    let filePath = path.join(dir, reqUrl === '/' ? 'index.html' : reqUrl);

    if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
      if (path.extname(reqUrl)) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        return res.end('Not Found');
      }
      filePath = path.join(dir, 'index.html');
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = mimeTypes[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, content) => {
      if (err) {
        console.log(`[500] ${req.url} (Error: ${err.message})`);
        res.writeHead(500);
        res.end('Server Error');
      } else {
        res.writeHead(200, {
          'Content-Type': contentType,
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        });
        res.end(content);
      }
    });
  });
}

const ports = [3000, 8080];
for (const port of ports) {
  try {
    const server = createServer();
    server.listen(port, () => {
      console.log(`===================================================`);
      console.log(`🚀 WrindhaOS Frontend & Backend API live on http://localhost:${port}`);
      console.log(`📡 Health Check: http://localhost:${port}/api/health`);
      console.log(`===================================================`);
    });
    server.on('error', (err) => {
      console.log(`Port ${port} error: ${err.message}`);
    });
  } catch (e) {
    console.log(`Could not bind port ${port}:`, e.message);
  }
}
