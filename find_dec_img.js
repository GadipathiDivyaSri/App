const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find DecorationImage constructor
const pos = js.indexOf('DecorationImage(');
if (pos !== -1) {
  console.log(js.substring(pos - 100, pos + 250));
} else {
  // Search for classes with fit, alignment, repeat
  const p = js.indexOf('new A.aqn(');
  console.log('aqn:', p !== -1 ? js.substring(p - 50, p + 150) : 'not found');
}

// Find ImageProvider constructors like NetworkImage or AssetImage
const pNet = js.indexOf('NetworkImage(');
console.log('NetworkImage:', pNet !== -1 ? js.substring(pNet - 50, pNet + 150) : 'not found');
