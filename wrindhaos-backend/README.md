# WrindhaOS Production Backend API

A modular, secure, production-ready REST API backend for **WrindhaOS** — a student productivity and life-management application built with **Node.js, Express.js, Supabase PostgreSQL**, Google Play Developer API server-side subscription verification, Firebase Cloud Messaging (FCM), and an Entitlement Control Engine.

---

## 🌟 Key Architecture & Capabilities

- 🔐 **Multi-Modal Authentication**: Supports Email OTP, Mobile Number OTP, and Google Sign-In with server-side identity verification.
- 💳 **Google Play Billing Verification ONLY**: Zero third-party gateways (No Razorpay, No Stripe, No PayPal). Purchase tokens are verified directly against the Google Play Developer API server-side.
- ⚡ **Entitlement Engine**:
  - **FREE Plan**: Eisenhower Matrix, Calendar, To-Do, **Max 2 active Habits**, **Max 2 active Subjects**, Ads Enabled (`ads_enabled = TRUE`).
  - **PREMIUM Plan**: Unlimited habits, unlimited subjects, all features unlocked, **Ad-Free** (`ads_enabled = FALSE`).
  - **Subscription Expiry**: Expiration returns status to FREE without deleting user data; re-subscribing restores full access.
- 🛡️ **Security**: JWT session tokens, UUID primary keys, Account Linking (`user_auth_identities`), Helmet, CORS, Rate Limiting, Input Validation, Audit Logging, and Row Level Security (RLS).
- ☁️ **Cloud Ready**: Configured for instant deployment on **Render** or cloud hosting platforms.

---

## 📁 Modular Project Structure

```text
wrindhaos-backend/
├── src/
│   ├── config/          # Environment, Supabase, Google Play, and Firebase configs
│   ├── constants/       # Entitlements, plans, features, and audit events
│   ├── middleware/      # Auth, premium entitlement limits, rate limits, validation, errors
│   ├── services/        # OTP, Auth, User, Entitlement, Subscription, Google Play, Notifications
│   ├── controllers/     # REST Controllers for all resources
│   ├── routes/          # Express Routers (/api/v1/)
│   └── utils/           # Response formatter, secure logger, audit logger
│   └── app.js           # Express App setup & middleware pipeline
├── migrations/          # 001_initial_schema.sql (PostgreSQL tables, indexes & RLS policies)
├── tests/               # Automated unit & integration tests
├── server.js            # Entry point
├── swagger.json         # OpenAPI 3.0 API schema specification
├── .env.example
├── package.json
└── README.md
```

---

## 🚀 Quick Start (Local Development)

1. **Install Dependencies**:
   ```bash
   npm install
   ```

2. **Configure Environment Variables**:
   Copy `.env.example` to `.env` and fill in your Supabase & Google credentials:
   ```bash
   cp .env.example .env
   ```

3. **Start Development Server**:
   ```bash
   npm start
   ```
   - Server runs on `http://localhost:5000`
   - Health Check: `http://localhost:5000/health`
   - Swagger OpenAPI Docs: `http://localhost:5000/api-docs`

4. **Run Automated Tests**:
   ```bash
   npm test
   ```

---

## 📡 REST API Version 1 Endpoints

### 🔐 Authentication (`/api/v1/auth`)
- `POST /api/v1/auth/email/request-otp` - Request 4-digit Email OTP code.
- `POST /api/v1/auth/email/verify-otp` - Verify Email OTP & issue JWT token.
- `POST /api/v1/auth/mobile/request-otp` - Request Mobile SMS OTP code.
- `POST /api/v1/auth/mobile/verify-otp` - Verify Mobile OTP & issue JWT token.
- `POST /api/v1/auth/google` - Verify Google OAuth ID token.

### 👤 User Profile (`/api/v1/users`)
- `GET /api/v1/users/me` - Fetch authenticated user profile.
- `PATCH /api/v1/users/me` - Update full name & profile avatar.
- `DELETE /api/v1/users/me` - Delete user account & associated data.

### ⚙️ Entitlements & Features (`/api/v1/entitlements`)
- `GET /api/v1/entitlements` - Fetch current plan (`FREE` / `PREMIUM`), `adsEnabled`, and feature limits.

### 💳 Subscriptions & Google Play (`/api/v1/subscriptions`)
- `POST /api/v1/subscriptions/google/verify` - Verify Google Play purchase token server-side and activate Premium.
- `GET /api/v1/subscriptions/me` - Get active subscription status and renewal date.
- `POST /api/v1/subscriptions/google/webhook` - Idempotent Google Play Developer Pub/Sub lifecycle webhook.

### 📝 To-Do Tasks (`/api/v1/todos`)
- `GET /api/v1/todos` - List user tasks.
- `POST /api/v1/todos` - Create task.
- `PATCH /api/v1/todos/:id` - Toggle completion / priority.
- `DELETE /api/v1/todos/:id` - Delete task.

### 🔥 Habits Tracker (`/api/v1/habits`)
- `GET /api/v1/habits` - List habits.
- `POST /api/v1/habits` - Create habit (**Enforces max 2 limit for Free plan**).
- `PATCH /api/v1/habits/:id` - Log daily completion / update streak.

### 📚 Subjects Planner (`/api/v1/subjects`)
- `GET /api/v1/subjects` - List subjects.
- `POST /api/v1/subjects` - Create subject (**Enforces max 2 limit for Free plan**).

### 📅 Calendar Events (`/api/v1/calendar`)
- `GET /api/v1/calendar/events` - List calendar events (Supports `?start=...&end=...` filtering).
- `POST /api/v1/calendar/events` - Create event.

### 🎯 Eisenhower Matrix (`/api/v1/eisenhower`)
- `GET /api/v1/eisenhower` - List 2x2 priority matrix tasks.
- `POST /api/v1/eisenhower` - Add task to Quadrant (1, 2, 3, or 4).

### 💬 Push Notifications (`/api/v1/notifications`)
- `POST /api/v1/notifications/register-device` - Register FCM device token.
- `DELETE /api/v1/notifications/unregister-device` - Unregister token.

---

## ☁️ Deployment on Render

1. Create a new **Web Service** on [Render](https://render.com).
2. Connect your Git repository containing `wrindhaos-backend`.
3. Set **Build Command**: `npm install`
4. Set **Start Command**: `npm start`
5. Environment Variables: Copy values from `.env.example` into Render's Environment settings.
6. Deployment is automatic and runs 24/7 independently of the developer's laptop!
