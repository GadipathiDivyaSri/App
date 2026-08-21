const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

for (const term of ['drawImage', 'ImageElement', 'HTMLImageElement', 'flutter-view', 'flt-picture', 'flt-canvas']) {
  let pos = js.indexOf(term);
  console.log(`Term "${term}": ${pos !== -1 ? 'found at ' + pos : 'not found'}`);
  if (pos !== -1) {
    console.log(js.substring(Math.max(0, pos - 50), Math.min(js.length, pos + 150)));
  }
}
