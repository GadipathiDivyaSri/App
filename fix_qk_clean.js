const fs = require('fs');

let js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// Build the clean, robust qK method
const cleanQk = `qK(a,b,c,d,e){
var s,r=t.p,q=null,p=A.n(a).ax.a===B.A,o,n=A.Q(20),m=A.b([],t.V);
var cPersonal=new A.x(1,0.81176,0.9098,0.83529,B.n);
var iPersonal=new A.x(1,0.2902,0.6078,0.3961,B.n);
var cCareer=new A.x(1,0.9686,0.7765,0.6902,B.n);
var iCareer=new A.x(1,0.9098,0.4588,0.3216,B.n);
var cStudies=new A.x(1,0.9725,0.8745,0.6510,B.n);
var iStudies=new A.x(1,0.8627,0.6431,0.1961,B.n);
var cCalendar=new A.x(1,0.8627,0.7882,0.9098,B.n);
var iCalendar=new A.x(1,0.5765,0.4118,0.7451,B.n);
var cPriority=new A.x(1,0.9098,0.7216,0.7373,B.n);
var iPriority=new A.x(1,0.8235,0.3569,0.4039,B.n);
var cAnalytics=new A.x(1,0.7686,0.8510,0.9098,B.n);
var iAnalytics=new A.x(1,0.2941,0.5529,0.7294,B.n);
var darkBg=new A.x(1,0.05098,0.10588,0.24314,B.n);
var darkIconGlow=new A.x(1,0.1647,0.52157,1.0,B.n);
var cardCol=cPersonal,iconCol=iPersonal;
if(e.indexOf("Career")!==-1){cardCol=cCareer;iconCol=iCareer;}
else if(e.indexOf("Studies")!==-1){cardCol=cStudies;iconCol=iStudies;}
else if(e.indexOf("Calendar")!==-1){cardCol=cCalendar;iconCol=iCalendar;}
else if(e.indexOf("Priority")!==-1){cardCol=cPriority;iconCol=iPriority;}
else if(e.indexOf("Analytics")!==-1){cardCol=cAnalytics;iconCol=iAnalytics;}
o=p?darkBg:cardCol;
var finalIconCol=p?darkIconGlow:iconCol;
if(!p)m.push(new A.aC(0,B.D,new A.x(0.03,0,0,0,B.n),B.ar,10));
s=A.cb(b,finalIconCol,q,28);
var textCol=p?B.e:new A.x(1,0.17647,0.149,0.1333,B.n);
var subTextCol=p?new A.x(1,0.494,0.592,0.7215,B.n):new A.x(1,0.5529,0.5098,0.4784,B.n);
var titleW=A.L(e,q,q,q,q,A.aw(q,q,textCol,q,q,q,q,q,q,q,q,16,q,q,B.x,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q);
var subW=A.L(d,1,B.b8,q,q,subTextCol,q,q,q);
var colContent=A.ab(A.b([titleW,B.aJ,subW],r),B.w,B.h,B.f,0,B.o);
var cardContent=A.ab(A.b([s,colContent],r),B.w,B.aC,B.f,0,B.o);
var containerDecor=new A.a0(o,q,q,n,m,q,B.r);
return A.c2(q,A.a4(q,cardContent,B.m,q,q,q,q,q,containerDecor,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q);
}`.replace(/\n/g, '');

const odPos = js.indexOf('A.Od.prototype={');
const qkPos = js.indexOf('qK(a,b,c,d,e){', odPos);
const qkEnd = js.indexOf('q,q,q,q,q,q)}}', qkPos) + 'q,q,q,q,q,q)}'.length;

console.log('qkPos:', qkPos, 'qkEnd:', qkEnd);
js = js.substring(0, qkPos) + cleanQk + js.substring(qkEnd);

fs.writeFileSync('build/web/main.dart.js', js, 'utf8');
console.log('Saved clean qK in build/web/main.dart.js');
