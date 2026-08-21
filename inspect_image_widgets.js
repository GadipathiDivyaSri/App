const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('NetworkImage');
if (pos !== -1) {
  console.log('NetworkImage at', pos);
  console.log(js.substring(pos - 100, pos + 300));
}

// Check how A.di or other Image widgets are constructed
const posDi = js.indexOf('function di(');
if (posDi !== -1) {
  console.log('di definition:', js.substring(posDi, posDi + 200));
}
