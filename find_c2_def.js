const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

let pos = 0;
while ((pos = js.indexOf('c2(a', pos)) !== -1) {
  console.log('Match at', pos, ':', js.substring(pos, pos + 200));
  pos += 4;
}
