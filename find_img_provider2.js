const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

for (const term of ['evict(', 'resolveStreamForKey(', 'createImageElement']) {
  let pos = js.indexOf(term);
  console.log(term, pos !== -1 ? pos : 'not found');
  if (pos !== -1) {
    console.log(js.substring(pos - 50, pos + 250));
  }
}
