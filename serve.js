const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
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
      res.writeHead(500);
      res.end('Server Error');
    } else {
      res.writeHead(200, {
        'Content-Type': contentType,
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-cache',
      });
      res.end(content);
    }
  });
}).listen(PORT, () => {
  console.log(`WrindhaOS App running cleanly on http://localhost:${PORT}`);
});
