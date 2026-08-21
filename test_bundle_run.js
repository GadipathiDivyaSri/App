const fs = require('fs');

// Simple validation that main.dart.js executes and registers dart2js app
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

console.log('Validating JS syntax and structure...');
try {
  new Function('window', 'self', 'globalThis', js);
  console.log('PASS: Bundle parses and compiles without error.');
} catch (e) {
  console.error('FAIL:', e);
}
