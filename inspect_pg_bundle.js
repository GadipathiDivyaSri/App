const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find navigation target for Personal Growth
const pos = js.indexOf('"Personal\\nGrowth"');
console.log('Context near Personal Growth:');
console.log(js.substring(pos - 200, pos + 400));
