const fs = require('fs');

let js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Target A.Od.prototype.qK
const oldQk = `s=A.cb(b,p?B.e:iconC,q,30)
s=A.a4(q,s,B.m,q,new A.a0(p?new A.x(1,0.0745,0.1843,0.36078,B.n):iconC,q,q,A.Q(16),q,q,B.r),q,54,q,q,q,q,54)`;

const newQk = `s=A.cb(b,p?new A.x(1,0.1647,0.52157,1.0,B.n):B.e,q,26)
s=A.a4(q,s,B.m,q,new A.a0(p?new A.x(1,0.0745,0.1843,0.36078,B.n):iconC,q,q,A.Q(14),q,q,B.r),q,48,q,q,q,q,48)`;

if (js.includes(oldQk)) {
  js = js.replace(oldQk, newQk);
  console.log('[OK] Fixed icon color to white on colored container in bundle!');
} else {
  console.log('[WARN] oldQk not found in bundle');
}

fs.writeFileSync('build/web/main.dart.js', js, 'utf8');
console.log('Saved bundle with visible icons!');
