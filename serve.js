const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
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

http.createServer((req, res) => {
  let reqUrl = req.url.split('?')[0];
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
      console.log(`[200] ${req.url} -> ${ext || 'html'}`);
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
}).listen(PORT, () => {
  console.log(`WrindhaOS App running cleanly on http://localhost:${PORT}`);
});
