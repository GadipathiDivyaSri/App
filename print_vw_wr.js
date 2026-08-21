const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const vwPos = js.indexOf('A.vW.prototype={');
const vwEnd = js.indexOf('A.agC.prototype={', vwPos);
console.log('=== A.vW.prototype ===');
console.log(js.substring(vwPos, vwEnd));

const wrPos = js.indexOf('A.Wr.prototype={');
const wrEnd = js.indexOf('A.avN.prototype={', wrPos);
console.log('=== A.Wr.prototype ===');
console.log(js.substring(wrPos, wrEnd));
