const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('B.a_x=');
console.log('B.a_x declaration:');
console.log(js.substring(pos, pos + 300));

const match = js.match(/B\.a_x\s*=\s*new\s*A\.([a-zA-Z0-9_$]+)/);
if (match) {
  const className = match[1];
  console.log('Class of B.a_x:', className);
  const classPos = js.indexOf(`A.${className}.prototype={`);
  console.log('Class prototype:');
  console.log(js.substring(classPos, classPos + 1500));
}
