const fs = require('fs');
const path = require('path');

const jsPath = path.join(__dirname, 'build', 'web', 'main.dart.js');
let code = fs.readFileSync(jsPath, 'utf8');

let idx = code.indexOf('qK(');
console.log('qK definition at:', idx);
if (idx !== -1) {
  console.log(code.substring(idx - 50, idx + 700));
}
