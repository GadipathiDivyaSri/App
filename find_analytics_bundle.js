const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

for (const term of ['Productivity Scorecard', 'Weekly Productivity Trend', 'Task Completion Rate', '3-Column Stat Card']) {
  let pos = js.indexOf(term);
  if (pos !== -1) {
    console.log(`Found "${term}" at ${pos}:`);
    console.log(js.substring(Math.max(0, pos - 150), Math.min(js.length, pos + 400)));
  }
}
