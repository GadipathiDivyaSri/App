const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const matches = [];
let idx = 0;
while ((idx = js.indexOf('createElement(', idx)) !== -1) {
  matches.push(js.substring(idx - 10, idx + 60));
  idx += 13;
}
console.log('Total createElement calls:', matches.length);
console.log('Sample createElement calls:', matches.slice(0, 15));
