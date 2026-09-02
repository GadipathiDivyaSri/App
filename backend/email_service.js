const https = require('https');

/**
 * Universal Email Dispatcher for WrindhaOS
 * Supports:
 * 1. Resend API (process.env.RESEND_API_KEY)
 * 2. MSG91 Widget API (process.env.MSG91_AUTH_KEY)
 */
async function sendEmailOtp({ email, otpCode, type = 'Verification' }) {
  console.log(`[EMAIL DISPATCHER] [${type}] Target: ${email} | Code: [${otpCode}]`);

  // 1. TRY RESEND API (Instant 100% Delivery if configured)
  const resendApiKey = process.env.RESEND_API_KEY;
  if (resendApiKey && resendApiKey.startsWith('re_')) {
    try {
      const payload = JSON.stringify({
        from: process.env.EMAIL_FROM || 'WrindhaOS <onboarding@resend.dev>',
        to: [email],
        subject: `[WrindhaOS] Your ${type} Code: ${otpCode}`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 16px;">
            <h2 style="color: #E87552; margin-bottom: 8px;">WrindhaOS ${type}</h2>
            <p style="color: #475569; font-size: 15px;">Use the 6-digit verification code below to complete your authentication:</p>
            <div style="background: #FFF9F0; border: 2px dashed #E87552; padding: 18px; text-align: center; border-radius: 12px; margin: 24px 0;">
              <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #1E293B;">${otpCode}</span>
            </div>
            <p style="color: #94A3B8; font-size: 13px;">This code is valid for 10 minutes. If you did not request this, please ignore this email.</p>
          </div>
        `,
      });

      const options = {
        hostname: 'api.resend.com',
        port: 443,
        path: '/emails',
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendApiKey}`,
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload),
        },
      };

      const res = await new Promise((resolve) => {
        const req = https.request(options, (res) => {
          let data = '';
          res.on('data', (c) => (data += c));
          res.on('end', () => resolve({ status: res.statusCode, data }));
        });
        req.on('error', (err) => resolve({ error: err.message }));
        req.write(payload);
        req.end();
      });

      if (res.status === 200 || res.status === 201) {
        console.log('✅ Email successfully delivered via Resend API to:', email);
        return { success: true, provider: 'resend', otpCode };
      }
    } catch (e) {
      console.warn('Resend dispatch failed, falling back to MSG91/local:', e.message);
    }
  }

  // 2. TRY MSG91 WIDGET API
  const msg91Key = process.env.MSG91_AUTH_KEY || '563368AbE6Nls32x6a9703baP1';
  const widgetId = process.env.MSG91_WIDGET_ID || '36687761466f383937303733';

  if (msg91Key && widgetId) {
    try {
      const payload = JSON.stringify({
        widgetId: widgetId,
        identifier: email,
        tokenAuth: msg91Key,
        otp: otpCode,
      });

      const options = {
        hostname: 'control.msg91.com',
        port: 443,
        path: '/api/v5/widget/sendOtp',
        method: 'POST',
        headers: {
          'authkey': msg91Key,
          'Content-Type': 'application/json',
          'Origin': 'http://localhost:8080',
          'Referer': 'http://localhost:8080/',
          'User-Agent': 'WrindhaOS-Backend/1.0',
          'Content-Length': Buffer.byteLength(payload),
        },
      };

      const res = await new Promise((resolve) => {
        const req = https.request(options, (msgRes) => {
          let resData = '';
          msgRes.on('data', (chunk) => (resData += chunk));
          msgRes.on('end', () => resolve({ status: msgRes.statusCode, data: resData }));
        });
        req.on('error', (err) => resolve({ error: err.message }));
        req.write(payload);
        req.end();
      });

      console.log(`[MSG91 DISPATCH RESULT] Status: ${res.status}, Response: ${res.data}`);
    } catch (e) {
      console.warn('MSG91 dispatch error:', e.message);
    }
  }

  return { success: true, provider: 'msg91_and_screen', otpCode };
}

module.exports = {
  sendEmailOtp,
};
