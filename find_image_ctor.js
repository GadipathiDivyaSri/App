const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find Image widget class
const pos = js.indexOf('Image(image:');
if (pos !== -1) {
  console.log(js.substring(pos - 100, pos + 200));
} else {
  // Let's find classes extending Widget that have fit or width or image
  const matches = js.match(/function\s+[a-zA-Z0-9_$]+\([^)]*\)\s*\{[^}]*imageProvider[^}]*\}/g);
  if (matches) {
    console.log('Matches:', matches.slice(0, 5));
  }
}
