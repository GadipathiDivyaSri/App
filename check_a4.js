const fs = require('fs');

const js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const pos = js.indexOf('a4(a,b,c,d,e,f,g,h,i,j,k,l,m){');
console.log('A.a4 definition:');
console.log(js.substring(pos, pos + 300));
