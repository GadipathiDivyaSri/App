const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('function a0(');
if (pos !== -1) {
  console.log('function a0:');
  console.log(js.substring(pos, pos + 250));
} else {
  const p2 = js.indexOf('a0:function a0(');
  console.log('a0:function a0:');
  console.log(js.substring(p2, p2 + 250));
}
