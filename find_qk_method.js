const fs = require('fs');
const path = require('path');

const jsPath = path.join(__dirname, 'build', 'web', 'main.dart.js');
let code = fs.readFileSync(jsPath, 'utf8');

let idx = 0;
while ((idx = code.indexOf('qK(a', idx + 1)) !== -1) {
  console.log(`\nqK(a match at ${idx}:`);
  console.log(code.substring(Math.max(0, idx - 100), Math.min(code.length, idx + 400)));
}
