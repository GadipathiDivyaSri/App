const fs = require('fs');
const js = fs.readFileSync('dd3_main.dart.js', 'utf8');

const target = '"Personal\\nGrowth"';
const pos = js.indexOf(target);
console.log('Pos in dd3:', pos);
if (pos !== -1) {
  console.log(js.substring(pos - 300, pos + 1500));
}
