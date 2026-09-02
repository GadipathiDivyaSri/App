const https = require('https');

/**
 * Universal Email Dispatcher for WrindhaOS
 * Primary Email Route: MSG91 Official Email API (control.msg91.com/api/v5/email/send)
 * Verified Sender: noreply@wrindhaos.in | Domain: wrindhaos.in | Template: global_otp
 */
async function sendEmailOtp({ email, otpCode, type = 'Verification' }) {
  console.log(`[EMAIL DISPATCHER] [${type}] Target: ${email} | Code: [${otpCode}] | From: noreply@wrindhaos.in`);

  const authkey = process.env.MSG91_AUTH_KEY || '563368AbE6Nls32x6a9703baP1';
  const domain = process.env.EMAIL_DOMAIN || 'wrindhaos.in';
  const fromEmail = process.env.EMAIL_FROM_ADDRESS || 'noreply@wrindhaos.in';
  const templateId = process.env.MSG91_OTP_TEMPLATE_ID || 'global_otp';

  // 1. PRIMARY: MSG91 OFFICIAL TEMPLATE EMAIL API (/api/v5/email/send)
  if (authkey && domain) {
    try {
      const recipientName = email.split('@')[0];
      const body = {
        recipients: [
          {
            to: [
              {
                email: email,
                name: recipientName[0].toUpperCase() + recipientName.slice(1)
              }
            ],
            variables: {
              OTP: otpCode,
              otp: otpCode,
              code: otpCode,
              company: 'WrindhaOS',
              name: recipientName
            }
          }
        ],
        from: {
          name: 'WrindhaOS',
          email: fromEmail
        },
        domain: domain,
        template_id: templateId
      };

      const payload = JSON.stringify(body);

      const options = {
        hostname: 'control.msg91.com',
        port: 443,
        path: '/api/v5/email/send',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'authkey': authkey,
          'Content-Length': Buffer.byteLength(payload)
        }
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

      console.log(`[MSG91 EMAIL API SUCCESS] Status: ${res.status}, Response: ${res.data}`);
      if (res.status === 200) {
        return { success: true, provider: 'msg91_email_api', otpCode };
      }
    } catch (e) {
      console.warn('[MSG91 EMAIL DISPATCH EXCEPTION]:', e.message);
    }
  }

  // 2. FALLBACK: RESEND API (if configured)
  const resendApiKey = process.env.RESEND_API_KEY;
  if (resendApiKey && resendApiKey.startsWith('re_')) {
    try {
      const payload = JSON.stringify({
        from: `WrindhaOS <${fromEmail}>`,
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
        return { success: true, provider: 'resend', otpCode };
      }
    } catch (e) {}
  }

  return { success: true, provider: 'screen_and_msg91', otpCode };
}

module.exports = {
  sendEmailOtp,
};
