const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('B.w=');
console.log('B.w definition:');
console.log(js.substring(pos, pos + 200));

const posA34 = js.indexOf('B.a34=');
console.log('B.a34 definition:');
console.log(js.substring(posA34, posA34 + 200));
