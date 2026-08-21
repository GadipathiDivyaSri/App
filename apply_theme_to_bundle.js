const fs = require('fs');
const path = require('path');

const jsPath = path.join(__dirname, 'build', 'web', 'main.dart.js');
let code = fs.readFileSync(jsPath, 'utf8');

console.log('Original bundle length:', code.length);

// 1. Update Core Color Constants:
// Primary Blue B.i (0xFF0D5CE5) -> Coral Orange #E87552
const oldBi = 'B.i=new A.x(1,0.050980392156862744,0.3607843137254902,0.8980392156862745,B.n)';
const newBi = 'B.i=new A.x(1,0.9098039215686274,0.4588235294117647,0.3215686274509804,B.n)';
code = code.replace(oldBi, newBi);

// Dark Card B.B (0xFF1E1F2B) -> Deep Midnight Blue #0D1B3E
const oldBB = 'B.B=new A.x(1,0.11764705882352941,0.12156862745098039,0.16862745098039217,B.n)';
const newBB = 'B.B=new A.x(1,0.050980392156862744,0.10588235294117647,0.24313725490196078,B.n)';
code = code.replace(oldBB, newBB);

// Dark Scaffold Background B.Jj (0xFF12131A) -> Deep Navy #060B1E
const oldDarkBg = 'B.Jj=new A.x(1,0.07058823529411765,0.07450980392156863,0.10196078431372549,B.n)';
const newDarkBg = 'B.Jj=new A.x(1,0.023529411764705882,0.043137254901960784,0.11764705882352941,B.n)';
code = code.replace(oldDarkBg, newDarkBg);

// Light Scaffold Background B.a0W (0xFFF7F8FF) -> Warm Oat Milk #FFF9F0
const oldLightBg = 'B.a0W=new A.x(1,0.9686274509803922,0.9725490196078431,1,B.n)';
const newLightBg = 'B.a0W=new A.x(1,1,0.9764705882352941,0.9411764705882353,B.n)';
code = code.replace(oldLightBg, newLightBg);

// Light Nav Background (0xFFEEF2FF) -> Pure White #FFFFFF
const oldLightNav = 'new A.x(1,0.9333333333333333,0.9490196078431372,1,B.n)';
const newLightNav = 'B.e'; // Pure white constant
code = code.replaceAll(oldLightNav, newLightNav);

// 2. Define Pastel Module Card Colors in the JS runtime
const pastelDefinitions = `
// --- INJECTED COZY PASTEL & DEEP NAVY COLORS ---
B.col_pg_bg = new A.x(1, 0.8117647, 0.9098039, 0.8352941, B.n); // #CFE8D5 Sage Mint
B.col_pg_icn = new A.x(1, 0.2901961, 0.6078431, 0.3960784, B.n); // #4A9B65

B.col_car_bg = new A.x(1, 0.9686274, 0.7764706, 0.6901961, B.n); // #F7C6B0 Soft Peach
B.col_car_icn = new A.x(1, 0.9098039, 0.4588235, 0.3215686, B.n); // #E87552 Coral

B.col_stu_bg = new A.x(1, 0.9725490, 0.8745098, 0.6509804, B.n); // #F8DFA6 Buttercup Yellow
B.col_stu_icn = new A.x(1, 0.8627451, 0.6431373, 0.1960784, B.n); // #DCA432 Gold

B.col_cal_bg = new A.x(1, 0.8627451, 0.7882353, 0.9098039, B.n); // #DCC9E8 Lavender
B.col_cal_icn = new A.x(1, 0.5764706, 0.4117647, 0.7450980, B.n); // #9369BE Violet

B.col_pri_bg = new A.x(1, 0.9098039, 0.7215686, 0.7372549, B.n); // #E8B8BC Blush Pink
B.col_pri_icn = new A.x(1, 0.8235294, 0.3568627, 0.4039216, B.n); // #D25B67 Rose

B.col_ana_bg = new A.x(1, 0.7686275, 0.8509804, 0.9098039, B.n); // #C4D9E8 Sky Blue
B.col_ana_icn = new A.x(1, 0.2941176, 0.5529412, 0.7294118, B.n); // #4B8DBA Blue

B.col_dark_icn_bg = new A.x(1, 0.0745098, 0.1843137, 0.3607843, B.n); // #132F5C
B.col_dark_icn_glow = new A.x(1, 0.1647059, 0.5215686, 1.0, B.n); // #2A85FF
B.col_chevron_light = new A.x(0.4, 0.1764706, 0.1490196, 0.1333333, B.n); // #2D2622 at 40%
B.col_chevron_dark = new A.x(1, 0.2980392, 0.3960784, 0.5411765, B.n); // #4C658A
B.chevron_icon = new A.aA(58133, "MaterialIcons", !1); // chevron_right
// --- END PASTEL DEFINITIONS ---
`;

if (!code.includes('B.col_pg_bg')) {
  code = code.replace('B.a84=', pastelDefinitions + '\nB.a84=');
}

// 3. Update the Home Grid Card method qK
const oldQK = `qK(a,b,c,d,e){var s,r,q=null,p=A.n(a).ax.a===B.A,o=p?B.B:B.e,n=A.Q(18),m=A.b([],t.V)
if(!p)m.push(new A.aC(0,B.D,A.O(8,B.j.m()>>>16&255,B.j.m()>>>8&255,B.j.m()&255),B.ar,10))
s=A.cb(b,B.i,q,26)
r=t.p
return A.c2(q,A.a4(q,A.ab(A.b([s,A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:B.M,q,q,q,q,q,q,q,q,16,q,q,B.x,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,1,B.b8,q,q,B.a0V,q,q,q)],r),B.w,B.h,B.f,0,B.o)],r),B.w,B.aC,B.f,0,B.o),new A.a0(q,A.O(16,16,16,16),o,n,m,q,B.r),q,q,q,new A.ao7(c))}`;

const newQK = `qK(a,b,c,d,e){
  var s,r,q=null,p=A.n(a).ax.a===B.A;
  var cardBg = B.e, icnBg = B.i, icnCol = B.e;
  if (e.indexOf("Personal") !== -1) { cardBg = B.col_pg_bg; icnBg = B.col_pg_icn; }
  else if (e.indexOf("Career") !== -1) { cardBg = B.col_car_bg; icnBg = B.col_car_icn; }
  else if (e.indexOf("Studies") !== -1) { cardBg = B.col_stu_bg; icnBg = B.col_stu_icn; }
  else if (e.indexOf("Calendar") !== -1) { cardBg = B.col_cal_bg; icnBg = B.col_cal_icn; }
  else if (e.indexOf("Priority") !== -1) { cardBg = B.col_pri_bg; icnBg = B.col_pri_icn; }
  else if (e.indexOf("Analytics") !== -1) { cardBg = B.col_ana_bg; icnBg = B.col_ana_icn; }
  if (p) { cardBg = B.B; icnBg = B.col_dark_icn_bg; icnCol = B.col_dark_icn_glow; }
  var n = A.Q(22);
  var m = A.b([], t.V);
  if (!p) m.push(new A.aC(0, B.D, A.O(4, 0, 0, 0), B.ar, 8));
  else m.push(new A.aC(0, B.D, A.O(6, 0, 0, 0), B.ar, 12));
  
  // Icon squircle container with white or glow icon
  var iconWidget = A.c2(q, A.cb(b, icnCol, q, 22), q, new A.a0(q, q, icnBg, A.Q(14), q, q, B.r), 44, 44);
  var chevronWidget = A.cb(B.chevron_icon, p ? B.col_chevron_dark : B.col_chevron_light, q, 20);
  var topRow = A.ah(A.b([iconWidget, chevronWidget], t.p), B.l, B.aC, B.f, 0, q);
  
  r = t.p;
  var bottomCol = A.ab(A.b([A.L(e,q,q,q,q,A.aw(q,q,p?B.e:B.M,q,q,q,q,q,q,q,q,16,q,q,B.x,q,1.2,!0,q,q,q,q,q,q,q,q),q,q,q),B.aJ,A.L(d,1,B.b8,q,q,B.a0V,q,q,q)],r),B.w,B.h,B.f,0,B.o);
  var content = A.ab(A.b([topRow, bottomCol], r), B.w, B.aC, B.f, 0, B.o);
  return A.c2(q, content, q, new A.a0(q, A.O(16,16,16,16), cardBg, n, m, q, B.r), q, q, q, new A.ao7(c));
}`;

if (code.includes(oldQK)) {
  code = code.replace(oldQK, newQK);
  console.log('Successfully replaced oldQK with enhanced newQK!');
} else {
  console.log('oldQK pattern did not match exactly, searching flexible regex...');
  const qkStart = 'qK(a,b,c,d,e){';
  const qkEnd = 'new A.ao7(c))}';
  const sIdx = code.indexOf(qkStart);
  if (sIdx !== -1) {
    const eIdx = code.indexOf(qkEnd, sIdx);
    if (eIdx !== -1) {
      const fullOld = code.substring(sIdx, eIdx + qkEnd.length);
      code = code.replace(fullOld, newQK);
      console.log('Successfully replaced flexible qK!');
    }
  }
}

fs.writeFileSync(jsPath, code, 'utf8');
console.log('New bundle length:', code.length);
