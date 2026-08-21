const fs = require('fs');
const js = fs.readFileSync('dd3_main.dart.js', 'utf8');

for (const term of ['Personal Growth', 'Career', 'Habit', 'Studies', 'Focus Score']) {
  const p = js.indexOf(term);
  console.log(`term "${term}": ${p}`);
}
