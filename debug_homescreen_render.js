const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Let's inspect A.Od.prototype.E and A.Od.prototype.qK
const odPos = js.indexOf('A.Od.prototype={');
console.log(js.substring(odPos, odPos + 1200));
