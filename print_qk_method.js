const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

console.log(js.substring(2496200, 2497600));
