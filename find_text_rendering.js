const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('fillText(');
console.log('fillText pos:', pos);
if (pos !== -1) {
  console.log(js.substring(pos - 50, pos + 250));
}

const posSpan = js.indexOf('createElement("flt-paragraph');
console.log('flt-paragraph pos:', posSpan);
if (posSpan !== -1) {
  console.log(js.substring(posSpan - 50, posSpan + 250));
}
