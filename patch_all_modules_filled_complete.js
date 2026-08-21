const fs = require('fs');

let js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// -------------------------------------------------------------
// 1. CAREER: Milestones in A.a55.prototype.$2 -> #F7C6B0 (Peach) & #E87552
// -------------------------------------------------------------
const oldA55 = `$2(a,b){var s,r,q=null,p=this.a[b],o=this.b,n=o?B.B:B.e,m=A.Q(16),l=A.b([],t.V)\nif(!o)l.push(new A.aC(0,B.D,A.O(5,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.bl,8))\no=p.f\ns=A.cb(o?B.hF:B.rW,B.i,q,q)`;
const newA55 = `$2(a,b){var s,r,q=null,p=this.a[b],o=this.b,n=o?B.B:new A.x(1,0.9686,0.7765,0.6902,B.n),m=A.Q(16),l=A.b([],t.V)
if(!o)l.push(new A.aC(0,B.D,new A.x(0.04,0,0,0,B.n),B.bl,8))
o=p.f
s=A.cb(o?B.hF:B.rW,o?B.e:new A.x(1,0.9098,0.4588,0.3216,B.n),q,q)`;

if (js.includes(oldA55)) {
  js = js.replace(oldA55, newA55);
  console.log('[OK] Patched Career Milestones (A.a55) to filled Soft Peach!');
} else {
  console.log('[WARN] oldA55 not found');
}

// -------------------------------------------------------------
// 2. PRIORITY: Summary Card, Quadrant mini cards, Task Items, Empty Card
// -------------------------------------------------------------
// aaY in A.YC.prototype
const oldAaY = `aaY(a){var s,r=this,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:B.e,n=A.Q(20),m=A.b([],t.V)\nif(!p)m.push(new A.aC(0,B.D,A.O(8,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.ar,10))`;
const newAaY = `aaY(a){var s,r=this,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:new A.x(1,0.9098,0.7216,0.7373,B.n),n=A.Q(20),m=A.b([],t.V)
if(!p)m.push(new A.aC(0,B.D,new A.x(0.04,0,0,0,B.n),B.ar,8))`;

if (js.includes(oldAaY)) {
  js = js.replace(oldAaY, newAaY);
  console.log('[OK] Patched Priority Summary Box (aaY) to filled Blush Pink!');
}

// Task items G7 in A.YC.prototype
const oldG7 = `G7(a,b,c){var s,r,q,p,o,n,m,l=null,k=A.n(a).ax.a===B.A,j=k?B.B:B.e,i=A.Q(16),h=A.b([],t.V)\nif(!k)h.push(new A.aC(0,B.D,A.O(5,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.bl,8))`;
const newG7 = `G7(a,b,c){var s,r,q,p,o,n,m,l=null,k=A.n(a).ax.a===B.A,j=k?B.B:new A.x(1,0.9098,0.7216,0.7373,B.n),i=A.Q(16),h=A.b([],t.V)
if(!k)h.push(new A.aC(0,B.D,new A.x(0.04,0,0,0,B.n),B.bl,8))`;

if (js.includes(oldG7)) {
  js = js.replace(oldG7, newG7);
  console.log('[OK] Patched Priority Task Cards (G7) to filled Blush Pink!');
}

// -------------------------------------------------------------
// 3. CALENDAR: Month Grid Container & Header in A.uh.prototype.aav
// -------------------------------------------------------------
const oldAav = `n=A.N3(A.bd(r),A.bm(r)),m=B.k.aR(A.rv(o),7),l=p?B.B:B.b0,k=A.Q(20),j=t.ax`;
const newAav = `n=A.N3(A.bd(r),A.bm(r)),m=B.k.aR(A.rv(o),7),l=p?B.B:new A.x(1,0.8627,0.7882,0.9098,B.n),k=A.Q(20),j=t.ax`;

if (js.includes(oldAav)) {
  js = js.replace(oldAav, newAav);
  console.log('[OK] Patched Calendar Month Grid (aav) to filled Lavender Violet!');
}

// -------------------------------------------------------------
// 4. ANALYTICS: 3-Column Stat Cards (zi) -> #C4D9E8 (Sky Blue) & #4B8DBA
// -------------------------------------------------------------
const oldZi = `zi(a,b,c,d,e){var s,r,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:B.e,n=A.Q(18),m=A.b([],t.V)\nif(!p)m.push(new A.aC(0,B.D,A.O(5,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.bl,8))\ns=A.cb(c,b,q,22)`;
const newZi = `zi(a,b,c,d,e){var s,r,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:new A.x(1,0.7686,0.851,0.9098,B.n),n=A.Q(18),m=A.b([],t.V)
if(!p)m.push(new A.aC(0,B.D,new A.x(0.04,0,0,0,B.n),B.bl,8))
var iconColor=p?new A.x(1,0.1647,0.52157,1.0,B.n):new A.x(1,0.294,0.553,0.729,B.n)
s=A.cb(c,iconColor,q,22)`;

if (js.includes(oldZi)) {
  js = js.replace(oldZi, newZi);
  console.log('[OK] Patched Analytics Stat Cards (zi) to filled Soft Sky Blue!');
}

fs.writeFileSync('build/web/main.dart.js', js, 'utf8');
console.log('Finished writing all filled module color patches!');
