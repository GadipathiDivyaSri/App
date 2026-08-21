const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

for (const term of ['assets/', 'AssetBundle', 'exactAsset', 'exactImage', 'a_asset', 'a43', 'a42']) {
  let pos = 0;
  while ((pos = js.indexOf(term, pos)) !== -1) {
    console.log(`Found "${term}" at ${pos}:`);
    console.log(js.substring(Math.max(0, pos - 100), Math.min(js.length, pos + 200)));
    pos += term.length;
  }
}
