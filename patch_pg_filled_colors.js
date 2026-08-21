const fs = require('fs');

let js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Target A.vW.prototype.vx (Personal Growth Menu Cards)
const oldVx = `vx(a,b,c,d,e){var s,r=null,q=A.n(a).ax.a===B.A,p=q?B.B:B.b0,o=A.Q(18),n=A.O(31,B.i.m()>>>16&255,B.i.m()>>>8&255,B.i.m()&255),m=A.Q(14)\nm=A.a4(r,A.cb(c,B.i,r,22),B.m,r,new A.a0(n,r,r,m,r,r,B.r),r,44,r,r,r,r,44)\nn=A.L(b,r,r,r,r,B.oH,r,r,r)\ns=t.p\nreturn A.c2(r,A.a4(r,A.ah(A.b([m,B.il,A.aQ(A.ab(A.b([n,B.aJ,A.L(e,r,r,r,r,A.aw(r,r,q?B.e:B.M,r,r,r,r,r,r,r,r,16,r,r,B.x,r,r,!0,r,r,r,r,r,r,r,r),r,r,r)],s),B.w,B.h,B.f,0,B.o),1),B.ng],s),B.l,B.h,B.f,0,r),B.m,r,new A.a0(p,r,r,o,r,r,B.r),r,r,r,B.cK,r,r,r),B.t,!1,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,d,r,r,r,r,r,r)}`;

console.log('oldVx found?', js.includes(oldVx));

// Filled pastel mint card for Personal Growth
const newVx = `vx(a,b,c,d,e){var s,r=null,q=A.n(a).ax.a===B.A,p=q?B.B:new A.x(1,0.81176,0.9098,0.83529,B.n),o=A.Q(18),n=q?new A.x(1,0.0745,0.1843,0.36078,B.n):new A.x(1,0.2902,0.6078,0.3961,B.n),m=A.Q(14)
m=A.a4(r,A.cb(c,q?new A.x(1,0.1647,0.52157,1.0,B.n):B.e,r,22),B.m,r,new A.a0(n,r,r,m,r,r,B.r),r,44,r,r,r,r,44)
n=A.L(b,r,r,r,r,A.aw(r,r,q?B.e:new A.x(1,0.2902,0.6078,0.3961,B.n),r,r,r,r,r,r,r,r,11,r,r,B.x,r,r,!0,r,r,r,r,r,r,r,r),r,r,r)
s=t.p
return A.c2(r,A.a4(r,A.ah(A.b([m,B.il,A.aQ(A.ab(A.b([n,B.aJ,A.L(e,r,r,r,r,A.aw(r,r,q?B.e:new A.x(1,0.17647,0.149,0.1333,B.n),r,r,r,r,r,r,r,r,16,r,r,B.x,r,r,!0,r,r,r,r,r,r,r,r),r,r,r)],s),B.w,B.h,B.f,0,B.o),1),B.ng],s),B.l,B.h,B.f,0,r),B.m,r,new A.a0(p,r,r,o,r,r,B.r),r,r,r,B.cK,r,r,r),B.t,!1,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,d,r,r,r,r,r,r)}`;

if (js.includes(oldVx)) {
  js = js.replace(oldVx, newVx);
  console.log('Successfully updated A.vW.prototype.vx to filled Pastel Mint cards!');
}

// Target A.Wr.prototype (Habit Tracker screen)
const oldWrE = `E(a){var s,r,q,p=this,o=null,n=A.n(a).ax.a===B.A,m=A.dd(o,o,A.c5(o,o,o,B.aI,o,o,new A.avN(a),o,o,o,o),B.a6I),l=A.js(B.i,B.dR,4,"habit_fab",new A.avO(p,a),B.cW),k=A.L("Current Streaks",o,o,o,o,A.aw(o,o,n?B.e:B.M,o,o,o,o,o,o,o,o,18,o,o,B.a_,o,o,!0,o,o,o,o,o,o,o,o),o,o,o),j=p.d,i=t.p
k=A.ah(A.b([k,A.L(j.length===0?"0 DAY STREAK":""+new A.aB(j,new A.avP(),A.a_(j).h("aB<1>")).gF(0)+" ACTIVE",o,o,o,o,B.oJ,o,o,o)],i),B.l,B.aC,B.f,0,o)
s=n?B.B:B.an
r=A.Q(20)
q=j.length
if(q===0)q=B.Iy
else{if(q>3)q=3
q=A.ah(A.acl(q,new A.avQ(p),!0,t.l7),B.l,B.hZ,B.f,0,o)}r=A.a4(o,q,B.m,o,new A.a0(s,o,o,r,o,o,B.r),o,o,o,B.LC,o,o,o)`;

console.log('oldWrE found?', js.includes(oldWrE));

const newWrE = `E(a){var s,r,q,p=this,o=null,n=A.n(a).ax.a===B.A,m=A.dd(o,o,A.c5(o,o,o,B.aI,o,o,new A.avN(a),o,o,o,o),B.a6I),l=A.js(n?B.i:new A.x(1,0.2902,0.6078,0.3961,B.n),B.dR,4,"habit_fab",new A.avO(p,a),B.cW),k=A.L("Current Streaks",o,o,o,o,A.aw(o,o,n?B.e:B.M,o,o,o,o,o,o,o,o,18,o,o,B.a_,o,o,!0,o,o,o,o,o,o,o,o),o,o,o),j=p.d,i=t.p
k=A.ah(A.b([k,A.L(j.length===0?"0 DAY STREAK":""+new A.aB(j,new A.avP(),A.a_(j).h("aB<1>")).gF(0)+" ACTIVE",o,o,o,o,B.oJ,o,o,o)],i),B.l,B.aC,B.f,0,o)
s=n?B.B:new A.x(1,0.81176,0.9098,0.83529,B.n)
r=A.Q(20)
q=j.length
if(q===0)q=B.Iy
else{if(q>3)q=3
q=A.ah(A.acl(q,new A.avQ(p),!0,t.l7),B.l,B.hZ,B.f,0,o)}r=A.a4(o,q,B.m,o,new A.a0(s,o,o,r,o,o,B.r),o,o,o,B.LC,o,o,o)`;

if (js.includes(oldWrE)) {
  js = js.replace(oldWrE, newWrE);
  console.log('Successfully updated HabitTracker streaks & FAB to Pastel Mint!');
}

// Target aay (Habit Item Card in HabitTracker)
const oldAay = `aay(a,b,c){var s,r,q,p,o=null,n=A.n(a).ax.a===B.A,m=J.d(b.i(0,"isCompleted"),!0),l=n?B.B:B.b0,k=A.Q(18),j=n?B.bw:B.e,i=A.Q(14)
i=A.a4(o,A.cb(t.tk.a(b.i(0,"icon")),B.i,o,22),B.m,o,new A.a0(j,o,o,i,o,o,B.r),o,44,o,o,o,o,44)
j=A.b1(b.i(0,"title"))
s=m?B.dZ:o
r=t.p
s=A.aQ(A.ab(A.b([A.L(j,o,o,o,o,A.aw(o,o,n?B.e:B.M,o,s,o,o,o,o,o,o,15,o,o,B.x,o,o,!0,o,o,o,o,o,o,o,o),o,o,o),B.aJ,A.L(A.b1(b.i(0,"frequency")),o,o,o,o,B.a3v,o,o,o)],r),B.w,B.h,B.f,0,B.o),1)
j=m?B.i:B.C
q=A.ef(B.i,B.z,2)
p=m?B.ti:o
return A.a4(o,A.ah(A.b([i,B.bT,s,A.c2(o,A.a4(o,p,B.m,o,new A.a0(j,o,q,o,o,o,B.aZ),o,28,o,o,o,o,28),B.t,!1,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,new A.avv(this,c,m),o,o,o,o,o,o),A.PY(B.fo,new A.avw(m),new A.avx(this,c,m,a),t.N)],r),B.l,B.h,B.f,0,o),B.m,o,new A.a0(l,o,o,k,o,o,B.r),o,o,B.fd,B.mg,o,o,o)}`;

console.log('oldAay found?', js.includes(oldAay));

const newAay = `aay(a,b,c){var s,r,q,p,o=null,n=A.n(a).ax.a===B.A,m=J.d(b.i(0,"isCompleted"),!0),l=n?B.B:new A.x(1,0.81176,0.9098,0.83529,B.n),k=A.Q(18),j=n?B.bw:new A.x(1,0.2902,0.6078,0.3961,B.n),i=A.Q(14)
i=A.a4(o,A.cb(t.tk.a(b.i(0,"icon")),B.e,o,22),B.m,o,new A.a0(j,o,o,i,o,o,B.r),o,44,o,o,o,o,44)
j=A.b1(b.i(0,"title"))
s=m?B.dZ:o
r=t.p
s=A.aQ(A.ab(A.b([A.L(j,o,o,o,o,A.aw(o,o,n?B.e:new A.x(1,0.17647,0.149,0.1333,B.n),o,s,o,o,o,o,o,o,15,o,o,B.x,o,o,!0,o,o,o,o,o,o,o,o),o,o,o),B.aJ,A.L(A.b1(b.i(0,"frequency")),o,o,o,o,B.a3v,o,o,o)],r),B.w,B.h,B.f,0,B.o),1)
var pGreen=new A.x(1,0.2902,0.6078,0.3961,B.n)
j=m?pGreen:B.C
q=A.ef(pGreen,B.z,2)
p=m?B.ti:o
return A.a4(o,A.ah(A.b([i,B.bT,s,A.c2(o,A.a4(o,p,B.m,o,new A.a0(j,o,q,o,o,o,B.aZ),o,28,o,o,o,o,28),B.t,!1,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,o,new A.avv(this,c,m),o,o,o,o,o,o),A.PY(B.fo,new A.avw(m),new A.avx(this,c,m,a),t.N)],r),B.l,B.h,B.f,0,o),B.m,o,new A.a0(l,o,o,k,o,o,B.r),o,o,B.fd,B.mg,o,o,o)}`;

if (js.includes(oldAay)) {
  js = js.replace(oldAay, newAay);
  console.log('Successfully updated HabitTracker habit cards to Pastel Mint!');
}

fs.writeFileSync('build/web/main.dart.js', js, 'utf8');
console.log('Saved patched bundle, length:', js.length);
