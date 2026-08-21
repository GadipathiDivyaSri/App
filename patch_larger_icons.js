const fs = require('fs');

let js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const oldQk = `s=A.cb(b,p?B.e:iconC,q,24)\ns=A.a4(q,s,B.m,q,new A.a0(p?new A.x(1,0.0745,0.1843,0.36078,B.n):iconC,q,q,A.Q(12),q,q,B.r),q,44,q,q,q,q,44)`;

const newQk = `s=A.cb(b,p?B.e:iconC,q,30)
s=A.a4(q,s,B.m,q,new A.a0(p?new A.x(1,0.0745,0.1843,0.36078,B.n):iconC,q,q,A.Q(16),q,q,B.r),q,54,q,q,q,q,54)`;

if (js.includes(oldQk)) {
  js = js.replace(oldQk, newQk);
  console.log('[OK] Updated Home module card icon container to 54x54 in bundle!');
}

fs.writeFileSync('build/web/main.dart.js', js, 'utf8');
console.log('Saved bundle with enlarged icons!');
