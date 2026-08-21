const fs = require('fs');
const { execSync } = require('child_process');

console.log('Extracting build/web/main.dart.js from commit dd3a0e2...');
const buf = execSync('git show dd3a0e2:build/web/main.dart.js', { maxBuffer: 50 * 1024 * 1024 });
fs.writeFileSync('clean_orig.js', buf);
console.log('clean_orig.js extracted successfully, length:', buf.length);

const js = fs.readFileSync('clean_orig.js', 'utf8');
const odPos = js.indexOf('A.Od.prototype={');
console.log('A.Od.prototype found at:', odPos);
if (odPos !== -1) {
  console.log('=== Original A.Od.prototype ===');
  console.log(js.substring(odPos, odPos + 1800));
}
