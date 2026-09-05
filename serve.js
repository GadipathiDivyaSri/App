const http = require('http');
const fs = require('fs');
const path = require('path');
const { handleApiRequest } = require('./backend/api_handler');
require('./backend/supabase_client');

const dir = __dirname;

const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.wasm': 'application/wasm',
};

// Global Exception Safety
process.on('uncaughtException', (err) => {
  console.error('[SERVER UNCAUGHT EXCEPTION]:', err);
});

process.on('unhandledRejection', (reason) => {
  console.error('[SERVER UNHANDLED REJECTION]:', reason);
});

function createServerInstance() {
  return http.createServer((req, res) => {
    // Enable CORS headers on all requests
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');

    if (req.method === 'OPTIONS') {
      res.writeHead(204);
      return res.end();
    }

    // Health Check Endpoint
    if (req.url === '/api/health' || req.url === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify({
        status: 'UP',
        service: 'WrindhaOS Production Web & API Server',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'production',
      }));
    }

    // 1. Route API requests to backend handler
    if (req.url.startsWith('/api/') || req.url === '/api') {
      return handleApiRequest(req, res);
    }

    // 2. Serve static frontend files
    let reqUrl = req.url.split('?')[0];
    if (reqUrl.startsWith('/WRINDHA_OS_APP/')) {
      reqUrl = reqUrl.substring(15) || '/';
    } else if (reqUrl.startsWith('/WRINDHA_OS_APP')) {
      reqUrl = reqUrl.substring(15) || '/';
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

    if (req.method === 'HEAD') {
      res.writeHead(200, {
        'Content-Type': contentType,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
      });
      return res.end();
    }

    fs.readFile(filePath, (err, content) => {
      if (err) {
        console.error(`[500] ${req.url} (Error: ${err.message})`);
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Internal Server Error');
      } else {
        res.writeHead(200, {
          'Content-Type': contentType,
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        });
        res.end(content);
      }
    });
  });
}

function startServerOnPort(ports, index = 0) {
  if (index >= ports.length) {
    console.error('Failed to bind server on any candidate port.');
    return;
  }

  const port = ports[index];
  const server = createServerInstance();

  server.listen(port, '0.0.0.0', () => {
    console.log(`===================================================`);
    console.log(`🚀 WrindhaOS Local Server Live:`);
    console.log(`👉 Main App:   http://localhost:${port}`);
    console.log(`👉 Loopback:   http://127.0.0.1:${port}`);
    console.log(`📡 Health Check: http://localhost:${port}/api/health`);
    console.log(`===================================================`);
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.warn(`Port ${port} is in use. Trying port ${ports[index + 1]}...`);
      startServerOnPort(ports, index + 1);
    } else {
      console.error(`Server error on port ${port}:`, err.message);
    }
  });
}

startServerOnPort([8080, 3000, 8000, 5000]);
