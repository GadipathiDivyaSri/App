const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const matches = [];
for (const term of ['obtainKey', 'createImageElement', 'HtmlImageElement', 'decodeImageFromList', 'instantiateImageCodec']) {
  let pos = js.indexOf(term);
  if (pos !== -1) {
    console.log(`Found "${term}" at ${pos}:`);
    console.log(js.substring(Math.max(0, pos - 100), Math.min(js.length, pos + 300)));
  }
}
