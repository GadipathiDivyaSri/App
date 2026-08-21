const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const a4kPos = js.indexOf('A.a4K.prototype={');
if (a4kPos !== -1) {
  console.log('=== A.a4K.prototype (Calendar Task Item) ===');
  console.log(js.substring(a4kPos, a4kPos + 1200));
}

const azDPos = js.indexOf('A.azD.prototype={');
if (azDPos !== -1) {
  console.log('=== A.azD.prototype (Priority Task Item) ===');
  console.log(js.substring(azDPos, azDPos + 1200));
}
