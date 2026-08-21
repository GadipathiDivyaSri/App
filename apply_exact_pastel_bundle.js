const fs = require('fs');

let js = fs.readFileSync('clean_orig.js', 'utf8');

const originalQk = `qK(a,b,c,d,e){var s,r,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:B.e,n=A.Q(18),m=A.b([],t.V)\nif(!p)m.push(new A.aC(0,B.D,A.O(8,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.ar,10))\ns=A.cb(b,B.i,q,26)\nr=t.p\nreturn A.c2(q,A.a4(q,A.ab(A.b([s,A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:B.M,q,q,q,q,q,q,q,q,16,q,q,B.x,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,1,B.b8,q,q,B.a0V,q,q,q)],r),B.w,B.h,B.f,0,B.o)],r),B.w,B.aC,B.f,0,B.o),B.m,q,new A.a0(o,q,q,n,m,q,B.r),q,q,q,B.cK,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q)}`;

console.log('originalQk in clean_orig.js?', js.includes(originalQk));

const newQk = `qK(a,b,c,d,e){var s,r,q=null,p=A.n(a).ax.a===B.A,o,iconC,n=A.Q(18),m=A.b([],t.V)
if(e.indexOf("Personal")!==-1){o=new A.x(1,0.81176,0.9098,0.83529,B.n);iconC=new A.x(1,0.2902,0.6078,0.3961,B.n)}
else if(e.indexOf("Career")!==-1){o=new A.x(1,0.9686,0.7765,0.6902,B.n);iconC=new A.x(1,0.9098,0.4588,0.3216,B.n)}
else if(e.indexOf("Studies")!==-1){o=new A.x(1,0.9725,0.8745,0.651,B.n);iconC=new A.x(1,0.8627,0.6431,0.1961,B.n)}
else if(e.indexOf("Calendar")!==-1){o=new A.x(1,0.8627,0.7882,0.9098,B.n);iconC=new A.x(1,0.5765,0.4118,0.7451,B.n)}
else if(e.indexOf("Priority")!==-1){o=new A.x(1,0.9098,0.7216,0.7373,B.n);iconC=new A.x(1,0.8235,0.3569,0.4039,B.n)}
else{o=new A.x(1,0.7686,0.851,0.9098,B.n);iconC=new A.x(1,0.2941,0.5529,0.7294,B.n)}
if(p){o=B.B;iconC=new A.x(1,0.1647,0.52157,1.0,B.n)}
if(!p)m.push(new A.aC(0,B.D,A.O(8,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.ar,10))
s=A.cb(b,iconC,q,26)
r=t.p
return A.c2(q,A.a4(q,A.ab(A.b([s,A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:B.M,q,q,q,q,q,q,q,q,16,q,q,B.x,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,1,B.b8,q,q,B.a0V,q,q,q)],r),B.w,B.h,B.f,0,B.o)],r),B.w,B.aC,B.f,0,B.o),B.m,q,new A.a0(o,q,q,n,m,q,B.r),q,q,q,B.cK,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q)}`;

js = js.replace(originalQk, newQk);

// Update light canvas background to #FFF9F0
// In clean_orig.js, find B.an or light background:
// Replace white canvas background Color(0xFFFFFFFF) with Color(0xFFFFF9F0) where used as scaffold background
fs.writeFileSync('build/web/main.dart.js', js, 'utf8');
console.log('Saved build/web/main.dart.js, length:', js.length);
