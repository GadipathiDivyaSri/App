const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('a4:function a4(');
if (pos !== -1) {
  console.log(js.substring(pos, pos + 400));
} else {
  const p2 = js.indexOf('a4(');
  console.log(js.substring(p2, p2 + 400));
}
