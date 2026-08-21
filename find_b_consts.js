const fs = require('fs');
const path = require('path');

const jsPath = path.join(__dirname, 'build', 'web', 'main.dart.js');
let code = fs.readFileSync(jsPath, 'utf8');

const targets = ['B.i=', 'B.B=', 'B.M=', 'B.a84='];
targets.forEach(t => {
  let idx = code.indexOf(t);
  console.log(`${t} at ${idx}:`);
  if (idx !== -1) {
    console.log(code.substring(idx, idx + 100));
  }
});
