const fs = require('fs');
const path = require('path');

const jsPath = path.join(__dirname, 'build', 'web', 'main.dart.js');
let code = fs.readFileSync(jsPath, 'utf8');

console.log('Original length:', code.length);

// 1. Check if already patched
if (code.includes('delBtnAct')) {
  console.log('Already patched!');
  process.exit(0);
}

// 2. Define custom classes and constants
const injection = `
// --- INJECTED DELETE ACCOUNT LOGIC ---
B.delTxt = new A.G("Delete Account", null, B.a28, null, null, null, null, null, null, null, null);
B.delIcn = new A.aV(new A.aA(57787, "MaterialIcons", !1), null, B.cb, null, null);
B.delTitle = new A.G("Delete Account", null, null, null, null, null, null, null, null, null, null);
B.delContent = new A.G("Are you sure you want to permanently delete your account? All your habits, tasks, calendar events, focus history, and personal data will be permanently erased. This action cannot be undone.", null, null, null, null, null, null, null, null, null, null);
B.delBtnAct = new A.G("Delete Permanently", null, B.fN, null, null, null, null, null, null, null, null);

A.delBtn = function delBtn(a, b) { this.a = a; this.b = b; };
A.delBtn.prototype = {
  $0() {
    var s = null;
    A.n0(s, s, !0, s, new A.delDlg(this.b), this.b, s, !0, t.z);
  },
  $S: 0
};

A.delDlg = function delDlg(a) { this.a = a; };
A.delDlg.prototype = {
  $1(a) {
    return A.pq(A.b([A.eX(B.eN, new A.ahx(a), null), A.eX(B.delBtnAct, new A.delConfirm(a, this.a), null)], t.p), B.delContent, B.delTitle);
  },
  $S: 47
};

A.delConfirm = function delConfirm(a, b) { this.a = a; this.b = b; };
A.delConfirm.prototype = {
  $0() {
    A.am(this.a, !1).aU(null);
    var s = A.fH(this.b, !1, t.R);
    try {
      if (typeof window !== "undefined") {
        if (window.fetch) {
          window.fetch("http://localhost:3000/api/user/delete-account", {
            method: "DELETE",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ userId: "u_1" })
          }).catch(function() {});
        }
        if (window.localStorage) {
          window.localStorage.clear();
        }
      }
    } catch(e) {}
    if (s.c && s.c.a) s.c.a = [];
    if (s.d && s.d.a) s.d.a = [];
    if (s.e && s.e.a) s.e.a = [];
    s.b = !1;
    s.Y();
  },
  $S: 0
};
// --- END INJECTED LOGIC ---
`;

// 3. Inject after B.a84 definition
const logoutTarget = 'B.a84=new A.G("Logout",null,B.a28,null,null,null,null,null,null,null,null)';
if (!code.includes(logoutTarget)) {
  console.error('Could not find logoutTarget in main.dart.js');
  process.exit(1);
}
code = code.replace(logoutTarget, logoutTarget + ';\n' + injection);

// 4. Inject Delete button below Logout button in ProfileScreen.build
const targetWidget = 'new A.F2(!0,new A.ahO(e,a3),d,d,d,d,B.m,d,!1,d,!0,d,new A.a04(B.a84,B.NM,d,d,d),d),B.cd';
const replacementWidget = 'new A.F2(!0,new A.ahO(e,a3),d,d,d,d,B.m,d,!1,d,!0,d,new A.a04(B.a84,B.NM,d,d,d),d),B.a7,new A.F2(!0,new A.delBtn(e,a3),d,d,d,d,B.m,d,!1,d,!0,d,new A.a04(B.delTxt,B.delIcn,d,d,d),d),B.cd';

if (!code.includes(targetWidget)) {
  console.error('Could not find targetWidget in main.dart.js');
  process.exit(1);
}
code = code.replace(targetWidget, replacementWidget);

fs.writeFileSync(jsPath, code, 'utf8');
console.log('Successfully patched build/web/main.dart.js! New length:', code.length);
