const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Look for image provider functions
const pos = js.indexOf('ImageProvider');
console.log('ImageProvider at:', pos);

// Let's search for functions returning Image or ImageProvider
const posExact = js.indexOf('assets/');
console.log('assets/ at:', posExact);

// Let's find how Image.network or Image.asset is called
const posNet = js.indexOf('network(');
console.log('network( at:', posNet);
if (posNet !== -1) {
  console.log(js.substring(posNet - 50, posNet + 200));
}
