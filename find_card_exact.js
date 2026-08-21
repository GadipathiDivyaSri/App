const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const target = '"Personal\\nGrowth"';
let pos = js.indexOf(target);
console.log('Pos:', pos);
if (pos !== -1) {
  console.log('Context before and after:');
  console.log(js.substring(pos - 400, pos + 400));
}
