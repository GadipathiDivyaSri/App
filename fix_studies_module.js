const fs = require('fs');

let js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Clean and perfect A.wQ.prototype.zj (Studies Screen)
const wqStart = js.indexOf('A.wQ.prototype={');
const wqEnd = js.indexOf('A.amK.prototype={', wqStart);

const perfectWq = `A.wQ.prototype={
E(a){var s=this,r=null
return A.cR(A.dd(r,r,A.c5(r,r,r,B.aI,r,r,new A.amK(a),r,r,r,r),B.ES),A.dX(A.ab(A.b([s.zj(a,B.n7,new A.amL(a),"Manage subjects, units & topics","Subject planner"),B.a5,s.zj(a,B.n6,new A.amM(a),"Weekly schedule","time table"),B.a5,s.zj(a,B.jB,new A.amN(a),"Deep work sessions & stopwatch","focus timer"),B.a5,s.zj(a,B.jA,new A.amO(a),"Pyramid structure (Short, Medium, Long)","Goals Hierarchy")],t.p),B.l,B.h,B.f,0,B.o),r,B.t,B.mh,r,r,B.Q),r,r)},
zj(a,b,c,d,e){var s,r,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:new A.x(1,0.9725,0.8745,0.651,B.n),n=A.Q(20),m=A.b([],t.V)
if(!p)m.push(new A.aC(0,B.D,new A.x(0.04,0,0,0,B.n),B.ar,8))
var iconBg=p?new A.x(1,0.0745,0.1843,0.36078,B.n):new A.x(1,0.8627,0.6431,0.1961,B.n)
s=A.a4(q,A.cb(b,p?new A.x(1,0.1647,0.52157,1.0,B.n):B.e,q,24),B.m,q,new A.a0(iconBg,q,q,q,q,q,B.aZ),q,50,q,q,q,q,50)
r=t.p
return A.c2(q,A.a4(q,A.ah(A.b([s,B.ZT,A.aQ(A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:new A.x(1,0.17647,0.149,0.1333,B.n),q,q,q,q,q,q,q,q,17,q,q,B.x,q,q,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,q,q,q,q,B.a34,q,q,q)],r),B.w,B.h,B.f,0,B.o),1),B.ng],r),B.l,B.h,B.f,0,q),B.m,q,new A.a0(o,q,q,n,m,q,B.r),q,q,q,B.LG,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q)}}\n`;

js = js.substring(0, wqStart) + perfectWq + js.substring(wqEnd);
console.log('[OK] Fixed Studies Screen prototype (A.wQ.prototype)!');

// Also update Subject Planner Screen in A.a_G.prototype
const oldAaQ = `s=A.O(31,B.i.m()>>>16&255,B.i.m()>>>8&255,B.i.m()&255)\nr=A.Q(14)\nr=A.a4(p,A.cb(t.tk.a(b.i(0,"icon")),B.i,p,24),B.m,p,new A.a0(s,p,p,r,p,p,B.r),p,48,p,p,p,p,48)`;
const newAaQ = `var sIconBg=n?new A.x(1,0.0745,0.1843,0.36078,B.n):new A.x(1,0.8627,0.6431,0.1961,B.n)
r=A.Q(14)
r=A.a4(p,A.cb(t.tk.a(b.i(0,"icon")),n?new A.x(1,0.1647,0.52157,1.0,B.n):B.e,p,24),B.m,p,new A.a0(sIconBg,p,p,r,p,p,B.r),p,48,p,p,p,p,48)`;

if (js.includes(oldAaQ)) {
  js = js.replace(oldAaQ, newAaQ);
  console.log('[OK] Updated SubjectPlanner subject icon container!');
}

// Update Subject Planner card background in A.a_G.prototype.aaQ
const oldSubCard = `m=n?B.B:B.e,l=A.Q(20),k=A.b([],t.V)\nif(!n)k.push(new A.aC(0,B.D,A.O(8,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.ar,10))`;
const newSubCard = `m=n?B.B:new A.x(1,0.9725,0.8745,0.651,B.n),l=A.Q(20),k=A.b([],t.V)
if(!n)k.push(new A.aC(0,B.D,new A.x(0.04,0,0,0,B.n),B.ar,8))`;

if (js.includes(oldSubCard)) {
  js = js.replace(oldSubCard, newSubCard);
  console.log('[OK] Updated SubjectPlanner subject cards to filled Buttercup Yellow!');
}

fs.writeFileSync('build/web/main.dart.js', js, 'utf8');
console.log('Saved fixed bundle successfully!');
