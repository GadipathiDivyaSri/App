const fs = require('fs');
const path = require('path');

const jsPath = path.join(__dirname, 'build', 'web', 'main.dart.js');
let code = fs.readFileSync(jsPath, 'utf8');

// Find occurrences of 'Personal Growth' or 'Wrindha' or 'Personal\nGrowth'
let idx = 0;
let matches = 0;
while ((idx = code.indexOf('Personal', idx + 1)) !== -1 && matches < 10) {
  matches++;
  console.log(`\n--- Match ${matches} at ${idx} ---`);
  console.log(code.substring(Math.max(0, idx - 150), Math.min(code.length, idx + 250)));
}
