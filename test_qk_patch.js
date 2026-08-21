const fs = require('fs');

let js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Target the exact qK method
const qkTarget = 'qK(a,b,c,d,e){var s,r,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:B.e,n=A.Q(18),m=A.b([],t.V)\nif(!p)m.push(new A.aC(0,B.D,A.O(8,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.ar,10))\ns=A.cb(b,B.i,q,26)\nr=t.p\nreturn A.c2(q,A.a4(q,A.ab(A.b([s,A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:B.M,q,q,q,q,q,q,q,q,16,q,q,B.x,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,1,B.b8,q,q,B.a0V,q,q,q)],r),B.w,B.h,B.f,0,B.o)],r),B.w,B.aC,B.f,0,B.o),B.m,q,new A.a0(o,q,q,n,m,q,B.r),q,q,q,B.cK,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q)}';

console.log('qkTarget found?', js.includes(qkTarget));

if (!js.includes(qkTarget)) {
  // Let's find with regex
  const match = js.match(/qK\(a,b,c,d,e\)\{var s,r,q=null[\s\S]*?q,q,q,q,q,q\)\}\}/);
  if (match) {
    console.log('Regex matched length:', match[0].length);
  } else {
    console.log('No regex match');
  }
}
