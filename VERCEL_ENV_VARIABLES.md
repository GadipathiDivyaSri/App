# Vercel Environment Variables & Deployment Guide (WrindhaOS)

This document contains the exact environment variables and step-by-step instructions required to deploy the WrindhaOS backend to **Vercel Serverless Production**.

---

## 1. Environment Variables Table

| Variable Name | Description | Value |
| :--- | :--- | :--- |
| `NODE_ENV` | Environment mode | `production` |
| `SUPABASE_URL` | Supabase PostgreSQL API Endpoint | `https://hkeyywopbkmlclsealbz.supabase.co` |
| `SUPABASE_KEY` | Supabase Service Role Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrZXl5d29wYmttbGNsc2VhbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODI3MTIxOSwiZXhwIjoyMTAzODQ3MjE5fQ.rAJQONxcr0PgCT-59ZfsjoyojY4-_g5aTaH2zwIntAg` |
| `SUPABASE_ANON_KEY` | Supabase Anonymous Client Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrZXl5d29wYmttbGNsc2VhbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgyNzEyMTksImV4cCI6MjEwMzg0NzIxOX0.axTZ1vLqZhquSfDhDXwIg4Sf2nioT8ZFjve39gr9QmY` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Master Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrZXl5d29wYmttbGNsc2VhbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODI3MTIxOSwiZXhwIjoyMTAzODQ3MjE5fQ.rAJQONxcr0PgCT-59ZfsjoyojY4-_g5aTaH2zwIntAg` |
| `DATABASE_URL` | Supabase Postgres Direct Connection | `postgresql://postgres:yb8J3XQGAcuh2SXc@db.hkeyywopbkmlclsealbz.supabase.co:5432/postgres` |
| `JWT_SECRET` | Production JWT Signature Secret | `wrindhaos_prod_secret_key_2026_super_secure` |
| `JWT_EXPIRES_IN` | Session Token Validity Duration | `30d` |
| `EMAIL_PROVIDER` | Email Dispatch Provider | `msg91` |
| `EMAIL_FROM_ADDRESS` | Sender Email Address | `noreply@wrindhaos.in` |
| `EMAIL_FROM_NAME` | Sender Display Name | `WrindhaOS` |
| `EMAIL_DOMAIN` | Email Domain Name | `wrindhaos.in` |
| `EMAIL_SENDER` | Sender Email Identifier | `noreply@wrindhaos.in` |
| `MSG91_AUTH_KEY` | MSG91 Live Authentication Key | `563368AbE6Nls32x6a9703baP1` |
| `MSG91_WIDGET_ID` | MSG91 OTP Widget Identifier | `36687761466f383937303733` |
| `MSG91_OTP_TEMPLATE_ID` | MSG91 Template Identifier | `global_otp` |

---

## 2. Raw `.env` Copy/Paste Block for Vercel Bulk Import

Use this block to copy and paste all variables into Vercel's Environment Variables input:

```env
NODE_ENV=production
SUPABASE_URL=https://hkeyywopbkmlclsealbz.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrZXl5d29wYmttbGNsc2VhbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODI3MTIxOSwiZXhwIjoyMTAzODQ3MjE5fQ.rAJQONxcr0PgCT-59ZfsjoyojY4-_g5aTaH2zwIntAg
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrZXl5d29wYmttbGNsc2VhbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgyNzEyMTksImV4cCI6MjEwMzg0NzIxOX0.axTZ1vLqZhquSfDhDXwIg4Sf2nioT8ZFjve39gr9QmY
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrZXl5d29wYmttbGNsc2VhbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODI3MTIxOSwiZXhwIjoyMTAzODQ3MjE5fQ.rAJQONxcr0PgCT-59ZfsjoyojY4-_g5aTaH2zwIntAg
DATABASE_URL=postgresql://postgres:yb8J3XQGAcuh2SXc@db.hkeyywopbkmlclsealbz.supabase.co:5432/postgres
JWT_SECRET=wrindhaos_prod_secret_key_2026_super_secure
JWT_EXPIRES_IN=30d
EMAIL_PROVIDER=msg91
EMAIL_FROM_ADDRESS=noreply@wrindhaos.in
EMAIL_FROM_NAME=WrindhaOS
EMAIL_DOMAIN=wrindhaos.in
EMAIL_SENDER=noreply@wrindhaos.in
MSG91_AUTH_KEY=563368AbE6Nls32x6a9703baP1
MSG91_WIDGET_ID=36687761466f383937303733
MSG91_OTP_TEMPLATE_ID=global_otp
```

---

## 3. Step-by-Step Instructions for Vercel Deployment

1. **Log into Vercel**:
   Go to [Vercel Dashboard](https://vercel.com/dashboard).

2. **Select your WrindhaOS Backend Project**:
   Click on your backend project repository.

3. **Navigate to Environment Variables**:
   Go to **Settings** -> **Environment Variables**.

4. **Add the Variables**:
   - Check **Production**, **Preview**, and **Development**.
   - Paste the block above into the key-value field.
   - Click **Save**.

5. **Redeploy Project**:
   - Go to the **Deployments** tab.
   - Click **...** next to the latest deployment and select **Redeploy** (or push a commit to GitHub `main`).
