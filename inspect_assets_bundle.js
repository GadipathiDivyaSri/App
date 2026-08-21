const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

console.log(js.substring(1231500, 1232200));
