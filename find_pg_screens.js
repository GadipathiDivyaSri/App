const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

for (const term of ['Current Streaks', 'Active Habits', 'Personal Growth Dashboard', 'Habit Momentum']) {
  let pos = 0;
  while ((pos = js.indexOf(term, pos)) !== -1) {
    console.log(`Found "${term}" at ${pos}:`);
    console.log(js.substring(Math.max(0, pos - 150), Math.min(js.length, pos + 400)));
    pos += term.length;
  }
}
