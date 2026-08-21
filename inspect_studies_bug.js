const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const wqPos = js.indexOf('A.wQ.prototype={');
const wqEnd = js.indexOf('A.amK.prototype={', wqPos);
console.log('=== A.wQ.prototype ===');
console.log(js.substring(wqPos, wqEnd));
