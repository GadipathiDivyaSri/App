const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Find all occurrences of module titles
const titles = ['Personal', 'Career', 'Studies', 'Calendar', 'Priority', 'Analytics'];
for (const t of titles) {
  let idx = 0;
  while ((idx = js.indexOf(t, idx)) !== -1) {
    // print snippet if near GridView / card builder
    const snippet = js.substring(Math.max(0, idx - 100), Math.min(js.length, idx + 200));
    if (snippet.includes('Habits') || snippet.includes('Pathways') || snippet.includes('Subplanner')) {
      console.log(`=== Match for ${t} ===`);
      console.log(snippet);
    }
    idx += t.length;
  }
}
