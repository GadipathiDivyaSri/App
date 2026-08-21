const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('cb(a,b,c,d){');
console.log('A.cb definition:');
console.log(js.substring(pos, pos + 300));
