const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find A.aV prototype
const pos = js.indexOf('A.aV.prototype={');
if (pos !== -1) {
  console.log('A.aV.prototype:');
  console.log(js.substring(pos, pos + 800));
}

// Find where Icon is built into element
const posElem = js.indexOf('A.aV.prototype');
console.log('A.aV references:');
for (const term of ['build(a){', 'createElement', 'IconElement']) {
  let p = js.indexOf(term);
  if (p !== -1) console.log(term, 'at', p);
}
