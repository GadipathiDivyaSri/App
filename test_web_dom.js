const fs = require('fs');

// Let's test what elements Flutter web produces by inspecting index.html and flutter_bootstrap.js
const html = fs.readFileSync('build/web/index.html', 'utf8');
console.log('index.html length:', html.length);
