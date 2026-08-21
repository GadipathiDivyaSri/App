const fs = require('fs');
const js = fs.readFileSync('dd3_main.dart.js', 'utf8');

const pos = js.indexOf('qK(a,b,c,d,e)');
if (pos !== -1) {
  console.log('qK in dd3a0e2:');
  console.log(js.substring(pos, pos + 800));
} else {
  console.log('qK not found in dd3_main.dart.js');
}
