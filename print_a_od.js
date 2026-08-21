const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('A.Od.prototype={');
console.log(js.substring(pos, pos + 2500));
