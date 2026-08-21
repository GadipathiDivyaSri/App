const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('A.ab5.prototype={');
console.log('A.ab5.prototype:');
console.log(js.substring(pos, pos + 300));
