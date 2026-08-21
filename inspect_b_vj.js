const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('B.VJ=');
console.log('B.VJ declaration:');
console.log(js.substring(pos, pos + 200));

// Find what class B.VJ is
const match = js.match(/B\.VJ\s*=\s*new\s*A\.([a-zA-Z0-9_$]+)/);
if (match) {
  const className = match[1];
  console.log('Class of B.VJ:', className);
  const classPos = js.indexOf(`A.${className}.prototype={`);
  console.log('Class prototype:');
  console.log(js.substring(classPos, classPos + 1500));
}
