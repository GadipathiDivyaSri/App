const fs = require('fs');
const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const matches = [...js.matchAll(/(\w+)\s*:\s*function\s*\([a-z0-9,\s]*\)\s*\{[^}]*Personal/g)];
console.log('Matches near Personal:', matches.length);
for (const m of matches) {
  console.log(m[0].substring(0, 150));
}

const qkMatches = [...js.matchAll(/([a-zA-Z0-9_$]+)\s*:\s*function\s*\([a-zA-Z0-9_$,\s]*\)\s*\{[^}]*Habits & Milestones/g)];
console.log('Matches for Habits & Milestones:', qkMatches.length);
for (const m of qkMatches) {
  console.log(m[0].substring(0, 200));
}

// Find declaration where prototype has qK or whatever function was called
const qkDef = [...js.matchAll(/qK\s*=\s*function|qK\s*:\s*function/g)];
console.log('qkDef matches:', qkDef.length);

const sQK = js.indexOf('.qK(');
if (sQK !== -1) {
  console.log('.qK call snippet:', js.substring(sQK - 100, sQK + 400));
}
