const fs = require('fs');

let js = fs.readFileSync('build/web/main.dart.js', 'utf8');

const oldQk = `s=A.cb(b,iconC,q,26)
r=t.p
return A.c2(q,A.a4(q,A.ab(A.b([s,A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:B.M,q,q,q,q,q,q,q,q,16,q,q,B.x,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,1,B.b8,q,q,B.a0V,q,q,q)],r),B.w,B.h,B.f,0,B.o)],r),B.w,B.aC,B.f,0,B.o),B.m,q,new A.a0(o,q,q,n,m,q,B.r),q,q,q,B.cK,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q)}`;

const newQk = `s=A.cb(b,p?B.e:iconC,q,24)
s=A.a4(q,s,B.m,q,new A.a0(p?new A.x(1,0.0745,0.1843,0.36078,B.n):iconC,q,q,A.Q(12),q,q,B.r),q,44,q,q,q,q,44)
r=t.p
return A.c2(q,A.a4(q,A.ab(A.b([s,A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:new A.x(1,0.17647,0.149,0.1333,B.n),q,q,q,q,q,q,q,q,16,q,q,B.x,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,1,B.b8,q,q,B.a0V,q,q,q)],r),B.w,B.h,B.f,0,B.o)],r),B.w,B.aC,B.f,0,B.o),B.m,q,new A.a0(o,q,q,n,m,q,B.r),q,q,q,B.cK,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q)}`;

if (js.includes(oldQk)) {
  js = js.replace(oldQk, newQk);
  console.log('[OK] Updated Home module card icon container in bundle!');
} else {
  console.log('[WARN] oldQk not found in bundle');
}

fs.writeFileSync('build/web/main.dart.js', js, 'utf8');
console.log('Saved patched bundle!');
