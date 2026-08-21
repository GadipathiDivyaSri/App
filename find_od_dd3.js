const fs = require('fs');
const js = fs.readFileSync('dd3_main.dart.js', 'utf8');

const pos = js.indexOf('A.Od.prototype');
console.log('A.Od.prototype in dd3:', pos);
if (pos !== -1) {
  console.log(js.substring(pos, pos + 1000));
}
