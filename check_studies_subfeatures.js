const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('A.amL.prototype={');
console.log('Studies subfeatures:');
console.log(js.substring(pos, pos + 1200));
