const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const odPos = js.indexOf('A.Od.prototype={');
console.log('odPos:', odPos);
const nextProto = js.indexOf('A.ab2.prototype={', odPos);
console.log('nextProto:', nextProto);

console.log('Snippet of A.Od.prototype:');
console.log(js.substring(odPos, nextProto + 20));
