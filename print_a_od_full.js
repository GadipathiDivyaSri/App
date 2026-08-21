const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const odPos = js.indexOf('A.Od.prototype={');
const ab2Pos = js.indexOf('A.ab2.prototype={', odPos);

console.log(js.substring(odPos, ab2Pos));
