const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const idx = js.indexOf('qK:function(');
console.log('qK index:', idx);
if (idx !== -1) {
  console.log(js.substring(idx, idx + 1200));
} else {
  // Try searching for qK(
  const matches = [...js.matchAll(/qK\s*:\s*function\s*\([^)]*\)\s*\{/g)];
  for (const m of matches) {
    console.log(m[0], js.substring(m.index, m.index + 800));
  }
}
