const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find prototypes for other modules:
const screens = ['Career', 'Studies', 'Calendar', 'Priority', 'Analytics'];
for (const s of ['Iv', 'a_u', 'lt', 'WE']) {
  const m = js.match(new RegExp(`B\\.${s}\\s*=\\s*new\\s*A\\.([a-zA-Z0-9_$]+)`));
  if (m) {
    console.log(`B.${s} -> class A.${m[1]}`);
    const pos = js.indexOf(`A.${m[1]}.prototype={`);
    console.log(js.substring(pos, pos + 400));
  }
}
