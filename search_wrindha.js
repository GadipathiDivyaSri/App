const fs = require('fs');
const js = fs.readFileSync('dd3_main.dart.js', 'utf8');

for (const term of ['Wrindha', 'wrindha', 'Alex', 'alex']) {
  const p = js.indexOf(term);
  console.log(`term "${term}": ${p}`);
}
