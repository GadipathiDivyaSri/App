const fs = require('fs');

const js = fs.readFileSync('clean_orig.js', 'utf8');

const pos = js.indexOf('A.wQ.prototype={');
const end = js.indexOf('A.amK.prototype={', pos);
console.log('Original A.wQ.prototype:');
console.log(js.substring(pos, end));
