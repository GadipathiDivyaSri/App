const fs = require('fs');
const path = require('path');

const jsPath = path.join(__dirname, 'build', 'web', 'main.dart.js');
let code = fs.readFileSync(jsPath, 'utf8');

console.log('Read main.dart.js, length:', code.length);

// Color Values:
// 1. Light background: 0xFFF7F8FF (4294439167) -> 0xFFFFF9F0 (4294965744)
// 2. Light primary / accent: 0xFF0D5CE5 (4279164133) -> 0xFFE87552 (4293424466)
// 3. Dark background: 0xFF12131A (4279374618) -> 0xFF060B1E (4278586142)
// 4. Dark card background: 0xFF1E1F2B (4280164139) -> 0xFF0D1B3E (4279049022)
// 5. Dark nav background: 0xFF1E1F2B (4280164139) -> 0xFF070D22 (4278652194)
// 6. Text dark: 0xFF1E293B (4280166715) or 0xFF0F172A (4279181098) -> 0xFF2D2622 (4281148962)
// 7. Light nav background: 0xFFEEF2FF (4293858047) -> 0xFFFFFFFF (4294967295)

const replacements = [
  { from: 4294439167, to: 4294965744, name: 'Light BG: F7F8FF -> FFF9F0' },
  { from: 4279164133, to: 4293424466, name: 'Primary Accent: 0D5CE5 -> E87552' },
  { from: 4279374618, to: 4278586142, name: 'Dark BG: 12131A -> 060B1E' },
  { from: 4280164139, to: 4279049022, name: 'Dark Card: 1E1F2B -> 0D1B3E' },
  { from: 4293858047, to: 4294967295, name: 'Light Nav: EEF2FF -> FFFFFF' },
  { from: 4280166715, to: 4281148962, name: 'Text Dark: 1E293B -> 2D2622' },
  { from: 4279181098, to: 4281148962, name: 'Text Dark: 0F172A -> 2D2622' },
];

let totalReplaced = 0;
replacements.forEach(r => {
  const fromStr = r.from.toString();
  const toStr = r.to.toString();
  const count = (code.split(fromStr).length - 1);
  if (count > 0) {
    code = code.replaceAll(fromStr, toStr);
    console.log(`[Replaced ${count}x] ${r.name}`);
    totalReplaced += count;
  } else {
    console.log(`[Not Found] ${r.name}`);
  }
});

fs.writeFileSync(jsPath, code, 'utf8');
console.log(`Successfully updated ${totalReplaced} color references in build/web/main.dart.js!`);
