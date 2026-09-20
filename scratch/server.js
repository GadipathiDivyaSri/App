const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8888;
const ROOT = path.join(__dirname, '..');

const server = http.createServer((req, res) => {
  let reqPath = decodeURIComponent(req.url.split('?')[0]);
  if (reqPath === '/') reqPath = '/WrindhaOS-v1.0.0-release.apk';
  const filePath = path.join(ROOT, reqPath);

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      return res.end('File Not Found');
    }

    const ext = path.extname(filePath).toLowerCase();
    let contentType = 'application/octet-stream';
    if (ext === '.apk') contentType = 'application/vnd.android.package-archive';
    if (ext === '.aab') contentType = 'application/x-author-bundle';

    res.writeHead(200, {
      'Content-Type': contentType,
      'Content-Length': stats.size,
      'Content-Disposition': `attachment; filename="${path.basename(filePath)}"`,
      'Access-Control-Allow-Origin': '*',
    });

    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(PORT, () => {
  console.log(`Local Download Server running at http://localhost:${PORT}/`);
});
