const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const icons = ['B.Ms', 'B.N6', 'B.rY', 'B.rV', 'B.nb', 'B.MK'];
for (const ic of icons) {
  const pos = js.indexOf(ic + '=');
  if (pos !== -1) {
    console.log(js.substring(pos, pos + 120));
  }
}
