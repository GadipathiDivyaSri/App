const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find other calls to A.a4
let p = 0, count = 0;
while ((p = js.indexOf('A.a4(', p)) !== -1 && count < 10) {
  console.log(`Call ${count}:`, js.substring(p, p + 120));
  p += 5;
  count++;
}
