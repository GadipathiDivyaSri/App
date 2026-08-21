const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find Image widget constructors
// In Flutter, Image has fields: imageProvider, frameBuilder, loadingBuilder, errorBuilder, width, height, color, opacity, colorBlendMode, fit, alignment, repeat, centerSlice, matchTextDirection, gaplessPlayback, isAntiAlias, filterQuality
const matches = [];
let pos = 0;
while ((pos = js.indexOf('width,height,fit', pos)) !== -1) {
  console.log('Found width,height,fit at', pos);
  console.log(js.substring(pos - 100, pos + 200));
  pos += 16;
}

// Search for any Image widget constructor
for (const term of ['image:', 'imageProvider', 'fit:', 'BoxFit']) {
  let p = js.indexOf(term);
  console.log(term, p);
}
