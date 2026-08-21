const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('zi(a,b,c,d,e){');
console.log('zi implementation:');
console.log(js.substring(pos, pos + 1000));
