const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find all matches for "qK:" or "qK=" or "qK :"
let pos = 0;
while ((pos = js.indexOf('qK', pos)) !== -1) {
  const snippet = js.substring(Math.max(0, pos - 30), Math.min(js.length, pos + 250));
  console.log(`Found qK at ${pos}:`);
  console.log(snippet);
  pos += 2;
}
