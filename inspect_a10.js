const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('a10(a,b,c,d){');
console.log('A.a10 definition:');
console.log(js.substring(pos, pos + 300));
