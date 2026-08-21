const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const matches = [];
let idx = 0;
while ((idx = js.indexOf('a4(', idx)) !== -1) {
  if (js.substring(idx - 5, idx) === 'A.a4=' || js.substring(idx - 2, idx) === 'a4(') {
    console.log(js.substring(idx - 10, idx + 100));
  }
  idx += 3;
}
