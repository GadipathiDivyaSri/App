const fs = require('fs');

try {
  const js = fs.readFileSync('build/web/main.dart.js', 'utf8');
  // Check basic syntax with new Function
  new Function(js);
  console.log('main.dart.js is 100% valid JavaScript syntax!');
} catch (e) {
  console.error('Syntax Error in main.dart.js:', e.message);
  console.error(e.stack);
}
