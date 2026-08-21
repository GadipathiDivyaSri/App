const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const ycPos = js.indexOf('A.YC.prototype={');
const ycEnd = js.indexOf('A.azC.prototype={', ycPos);
console.log('=== A.YC.prototype full ===');
console.log(js.substring(ycPos, ycEnd));
