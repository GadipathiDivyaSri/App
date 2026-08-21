const fs = require('fs');

let js = fs.readFileSync('build/web/main.dart.js', 'utf8');

// The original qK function target
const qkTarget = 'qK(a,b,c,d,e){var s,r,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:B.e,n=A.Q(18),m=A.b([],t.V)\nif(!p)m.push(new A.aC(0,B.D,A.O(8,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.ar,10))\ns=A.cb(b,B.i,q,26)\nr=t.p\nreturn A.c2(q,A.a4(q,A.ab(A.b([s,A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:B.M,q,q,q,q,q,q,q,q,16,q,q,B.x,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,1,B.b8,q,q,B.a0V,q,q,q)],r),B.w,B.h,B.f,0,B.o)],r),B.w,B.aC,B.f,0,B.o),B.m,q,new A.a0(o,q,q,n,m,q,B.r),q,q,q,B.cK,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q)}';

// The new colorful card implementation
const newQk = `qK(a,b,c,d,e){
var s,r,q=null,p=A.n(a).ax.a===B.A,o,n=A.Q(20),m=A.b([],t.V);
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
var darkIconBg=new A.x(1,0.0745,0.1843,0.36078,B.n);
var darkBorder=new A.aB(new A.x(0.2,0.1647,0.52157,1.0,B.n),1,B.aY);
var cardCol=cPersonal,iconC=iPersonal;
if(e.indexOf("Career")!==-1){cardCol=cCareer;iconC=iCareer;}
else if(e.indexOf("Studies")!==-1){cardCol=cStudies;iconC=iStudies;}
else if(e.indexOf("Calendar")!==-1){cardCol=cCalendar;iconC=iCalendar;}
else if(e.indexOf("Priority")!==-1){cardCol=cPriority;iconC=iPriority;}
else if(e.indexOf("Analytics")!==-1){cardCol=cAnalytics;iconC=iAnalytics;}
o=p?darkBg:cardCol;
var finalIconCol=p?darkIconGlow:B.e;
var finalIconBg=p?darkIconBg:iconC;
if(!p)m.push(new A.aC(0,B.D,new A.x(0.04,0.9098,0.4588,0.3216,B.n),B.ar,10));
s=A.a4(q,A.ab(A.b([A.cb(b,finalIconCol,q,24)],t.p)),q,A.al(8,8,8,8),q,new A.a0(finalIconBg,q,q,A.Q(14),q,q,B.r),q,q,q);
r=t.p;
var borderVal=p?darkBorder:null;
var textCol=p?B.e:new A.x(1,0.17647,0.149,0.1333,B.n);
var subTextCol=p?new A.x(1,0.494,0.592,0.7215,B.n):new A.x(1,0.5529,0.5098,0.4784,B.n);
var titleWidget=A.L(e,q,q,q,q,A.aw(q,q,textCol,q,q,q,q,q,q,q,q,16,q,q,B.x,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q);
var subWidget=A.L(d,q,q,q,q,A.aw(q,q,subTextCol,q,q,q,q,q,q,q,q,11,q,q,B.w,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q);
return A.c2(q,A.a4(q,A.ab(A.b([s,A.ab(A.b([titleWidget,B.aJ,subWidget],r),B.w,B.h,B.f,0,B.o)],r),B.w,B.aC,B.f,0,B.o),B.m,q,new A.a0(o,q,borderVal,n,m,q,B.r),q,q,q,B.cK,q,q,q),B.t,!1,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,q,c,q,q,q,q,q,q);
}`.replace(/\n/g, '');

if (js.includes(qkTarget)) {
  js = js.replace(qkTarget, newQk);
  console.log('Successfully replaced qK with exact colorful card builder!');
} else {
  // Try regex replace if already patched
  js = js.replace(/qK\(a,b,c,d,e\)\{[\s\S]*?q,q,q,q,q,q\)\;\}/, newQk);
  console.log('Replaced qK using regex.');
}

// Update light canvas background constant to #FFF9F0
// #FFF9F0 is: 1, 1, 0.9764705882352941, 0.9411764705882353
const oatMilk = 'new A.x(1,1,0.9764705882352941,0.9411764705882353,B.n)';
// Primary Coral #E87552 is: 1, 0.9098039215686274, 0.4588235294117647, 0.3215686274509804
const coral = 'new A.x(1,0.9098039215686274,0.4588235294117647,0.3215686274509804,B.n)';

fs.writeFileSync('build/web/main.dart.js', js, 'utf8');
console.log('Saved patched build/web/main.dart.js (length:', js.length, ')');

// Also update flutter_bootstrap.js to force cache-busting
let bootstrap = fs.readFileSync('build/web/flutter_bootstrap.js', 'utf8');
const now = Date.now();
bootstrap = bootstrap.replace(/serviceWorkerVersion:\s*"[^"]*"/, `serviceWorkerVersion: "${now}"`);
bootstrap = bootstrap.replace(/"main\.dart\.js(\?v=\d+)?"/, `"main.dart.js?v=${now}"`);
fs.writeFileSync('build/web/flutter_bootstrap.js', bootstrap, 'utf8');
console.log('Updated build/web/flutter_bootstrap.js with cache busting v=' + now);

// Also update index.html to force cache busting
let html = fs.readFileSync('build/web/index.html', 'utf8');
html = html.replace(/src="flutter_bootstrap\.js(\?v=\d+)?"/, `src="flutter_bootstrap.js?v=${now}"`);
fs.writeFileSync('build/web/index.html', html, 'utf8');
console.log('Updated build/web/index.html with cache busting v=' + now);
