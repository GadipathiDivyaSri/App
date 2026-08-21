const fs = require('fs');
const js = fs.readFileSync('dd3_main.dart.js', 'utf8');

const target = 'Habits & Milestones';
const pos = js.indexOf(target);
console.log('Pos for Habits & Milestones in dd3:', pos);
if (pos !== -1) {
  console.log(js.substring(pos - 400, pos + 800));
}
