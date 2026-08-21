const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find DecorationImage or ImageProvider classes in bundle
const matches = [];
for (const term of ['DecorationImage', 'AssetImage', 'NetworkImage', 'Image.asset', 'Image.network', 'MemoryImage', 'FileImage', 'ExactAssetImage']) {
  let pos = 0;
  while ((pos = js.indexOf(term, pos)) !== -1) {
    console.log(`Found "${term}" at ${pos}:`);
    console.log(js.substring(Math.max(0, pos - 100), Math.min(js.length, pos + 250)));
    pos += term.length;
  }
}
