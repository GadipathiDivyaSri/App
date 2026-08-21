const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Inspect A.a55 (Career items)
const a55Pos = js.indexOf('A.a55.prototype={');
if (a55Pos !== -1) {
  console.log('=== A.a55.prototype (Career Milestone Item) ===');
  console.log(js.substring(a55Pos, a55Pos + 1200));
}

// Inspect A.uh (Calendar Screen)
const uhPos = js.indexOf('A.uh.prototype={');
if (uhPos !== -1) {
  console.log('=== A.uh.prototype (Calendar Screen) ===');
  console.log(js.substring(uhPos, uhPos + 1600));
}

// Inspect A.YC (Priority Screen)
const ycPos = js.indexOf('A.YC.prototype={');
if (ycPos !== -1) {
  console.log('=== A.YC.prototype (Priority Screen) ===');
  console.log(js.substring(ycPos, ycPos + 1600));
}
