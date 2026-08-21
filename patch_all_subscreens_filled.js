const fs = require('fs');

let js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// 1. Studies cards in A.wQ.prototype.zj
const oldZj = `zj(a,b,c,d,e){var s,r,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:B.e,n=A.Q(20),m=A.b([],t.V)\nif(!p)m.push(new A.aC(0,B.D,A.O(8,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.ar,10))\ns=A.O(B.d.aE(25.5),B.i.m()>>>16&255,B.i.m()>>>8&255,B.i.m()&255)\ns=A.a4(q,A.cb(b,B.i,q,24),B.m,q,new A.a0(s,q,q,q,q,q,B.aZ),q,50,q,q,q,q,50)\nr=t.p\nreturn A.c2(q,A.a4(q,A.ah(A.b([s,B.ZT,A.aQ(A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:B.M,q,q,q,q,q,q,q,q,17,q,q,B.x,q,q,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,q,q,q,q,B.a34,q,q,q)],r),B.w,B.h,B.f,0,B.o),1),B.ng],r),B.l,B.h,B.f,0,q),B.m,q,new A.a0(o,q,q,n,m,q,B.r),q,q,q,B.LG,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q)}`;

const newZj = `zj(a,b,c,d,e){var s,r,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:new A.x(1,0.9725,0.8745,0.651,B.n),n=A.Q(20),m=A.b([],t.V)
if(!p)m.push(new A.aC(0,B.D,new A.x(0.04,0,0,0,B.n),B.ar,8))
var iconBg=p?new A.x(1,0.0745,0.1843,0.36078,B.n):new A.x(1,0.8627,0.6431,0.1961,B.n)
s=A.a4(q,A.cb(b,p?new A.x(1,0.1647,0.52157,1.0,B.n):B.e,q,24),B.m,q,new A.a0(iconBg,q,q,A.Q(14),q,q,B.r),q,50,q,q,q,q,50)
r=t.p
return A.c2(q,A.a4(q,A.ah(A.b([s,B.ZT,A.aQ(A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:new A.x(1,0.17647,0.149,0.1333,B.n),q,q,q,q,q,q,q,q,17,q,q,B.x,q,q,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,q,q,q,q,A.aw(q,q,p?new A.x(1,0.494,0.592,0.7215,B.n):new A.x(1,0.5529,0.5098,0.4784,B.n),q,q,q,q,q,q,q,q,12,q,q,B.w,q,q,!0,q,q,q,q,q,q,q,q),q,q,q)],r),B.w,B.h,B.f,0,B.o),1),B.ng],r),B.l,B.h,B.f,0,q),B.m,q,new A.a0(o,q,q,n,m,q,B.r),q,q,q,B.LG,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q)}`;

if (js.includes(oldZj)) {
  js = js.replace(oldZj, newZj);
  console.log('Successfully updated Studies menu cards (zj) to filled Buttercup Yellow!');
}

// 2. Update Career Screen Roadmap Card in A.uk.prototype
const oldCareerRoadmapCard = `r=A.c2(m,A.a4(m,A.ah(A.b([A.a4(m,B.O4,B.m,m,new A.a0(A.O(31,B.i.m()>>>16&255,B.i.m()>>>8&255,B.i.m()&255),m,m,A.Q(16),m,m,B.r),m,50,m,m,m,m,50),B.il,A.aQ(A.ab(B.RM,B.w,B.h,B.f,0,B.o),1),B.Nc],n),B.l,B.h,B.f,0,m),B.m,m,new A.a0(q,m,o,p,r,m,B.r),m,m,m,B.S,m,m,1/0),B.t,!1,m,m,m,m,m,m,m,m,m,m,m,m,m,m,m,m,new A.a54(a),m,m,m,m,m,m)`;

const newCareerRoadmapCard = `var cPeach=new A.x(1,0.9686,0.7765,0.6902,B.n),cCoral=new A.x(1,0.9098,0.4588,0.3216,B.n);
var cIconBg=h?new A.x(1,0.0745,0.1843,0.36078,B.n):cCoral;
var cardBg=h?B.B:cPeach;
r=A.c2(m,A.a4(m,A.ah(A.b([A.a4(m,A.cb(B.gN,h?new A.x(1,0.1647,0.52157,1.0,B.n):B.e,m,26),B.m,m,new A.a0(cIconBg,m,m,A.Q(16),m,m,B.r),m,50,m,m,m,m,50),B.il,A.aQ(A.ab(B.RM,B.w,B.h,B.f,0,B.o),1),B.Nc],n),B.l,B.h,B.f,0,m),B.m,m,new A.a0(cardBg,m,h?o:null,p,r,m,B.r),m,m,m,B.S,m,m,1/0),B.t,!1,m,m,m,m,m,m,m,m,m,m,m,m,m,m,m,m,new A.a54(a),m,m,m,m,m,m)`;

if (js.includes(oldCareerRoadmapCard)) {
  js = js.replace(oldCareerRoadmapCard, newCareerRoadmapCard);
  console.log('Successfully updated Career Roadmap card to filled Soft Peach!');
}

fs.writeFileSync('build/web/main.dart.js', js, 'utf8');
console.log('Finished patching all module screens!');
