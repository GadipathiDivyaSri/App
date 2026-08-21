const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find all matches for "Wrindha"
let p = 0;
while ((p = js.indexOf('Wrindha', p)) !== -1) {
  console.log('Match at', p, ':', js.substring(p - 100, p + 500));
  p += 7;
}
