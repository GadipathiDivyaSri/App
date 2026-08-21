const fs = require('fs');
const js = fs.readFileSync('dd3_main.dart.js', 'utf8');

// Find all methods near "WrindhaOS"
const pos = js.indexOf('"WrindhaOS"');
console.log('Pos for WrindhaOS in dd3:', pos);
if (pos !== -1) {
  console.log(js.substring(pos - 200, pos + 1500));
}
