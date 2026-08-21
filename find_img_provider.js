const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

for (const term of ['AssetImage', 'exactAsset', 'AssetBundle', 'package:flutter/src/painting/image_provider.dart', 'AssetBundleImageKey']) {
  let pos = js.indexOf(term);
  if (pos !== -1) {
    console.log(`Found "${term}" at ${pos}:`);
    console.log(js.substring(pos, pos + 300));
  }
}
