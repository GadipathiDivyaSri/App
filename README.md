# 🚀 WrindhaOS - Complete All-in-One Productivity & Life Operating System

WrindhaOS is a comprehensive, production-grade mobile and web application built with **Flutter**, **Node.js / Express REST API**, and **Supabase PostgreSQL**. It combines 15+ habit tracking, financial budgeting, academic management, goal setting, career roadmap, schedule calendar, and priority matrix tools under a unified **Zero-Admin-Access & Developer-Encryption Security Architecture**.

---

## 📁 Repository Directory Structure

```text
productivity_app/
├── lib/                             # Flutter Mobile & Web Source Code
│   ├── main.dart                    # Application Entry Point
│   ├── providers/                   # State Management (AppProvider, etc.)
│   └── screens/                     # 15+ Feature Modules (Habits, Expenses, Goals, Journal, etc.)
├── pubspec.yaml                     # Flutter Package Dependencies
├── serve.js                         # Static Web Server Entry Point (Port 8080)
├── wrindhaos-backend/               # Node.js + Express REST API Backend
│   ├── src/
│   │   ├── app.js                   # Express App Definition & Middleware
│   │   ├── controllers/             # Auth, User, Admin, Entitlement, Privacy Controllers
│   │   ├── middleware/              # Auth JWT, Admin Authorization, Rate Limiting, Errors
│   │   ├── routes/                  # REST API Route Declarations
│   │   └── services/                # Google Play Billing, pgcrypto Encryption Service
│   ├── migrations/                  # PostgreSQL Database DDL Migrations
│   │   ├── 000_wrindhaos_master_database_schema.sql  # ★ CONSOLIDATED MASTER SCHEMA
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_admin_schema.sql
│   │   ├── 003_complete_wrindhaos_schema.sql
│   │   └── 004_zero_admin_access_security.sql
│   ├── public/admin/                # Executive Backoffice Super Admin Web Portal
│   ├── tests/                       # Automated Security & Backend Test Suites
│   │   ├── backend.test.js          # 10/10 REST API Tests
│   │   └── zeroAdminAccess.test.js  # 16/16 Zero-Admin Security Tests
│   ├── server.js                    # Backend Server Entry Point (Port 5000)
│   └── package.json                 # Node.js Dependencies
└── README.md                        # Master Project Documentation
```

---

## 🔒 Security Architecture Highlights

1. **Owner-Only RLS (`auth.uid() = user_id`)**:
   Enforced across all 19 private user tables (`habits`, `expenses`, `journal_entries`, `goals_hierarchy`, `subjects`, `calendar_events`, etc.).
2. **Zero Admin Read Policies**:
   Administrators (`SUPER_ADMIN`, `SUPPORT_AGENT`, `FINANCE_ADMIN`, `MODERATOR`) can **NEVER** view, search, export, or modify private user content. Admin APIs return only operational metadata (`account_status`, `subscription_plan`, `usage_counts`).
3. **Developer/DBA AES-256 Ciphertext Encryption**:
   Sensitive text fields (`journal_entries.body_content`) are encrypted at rest via `encryptionService.js` and `pgcrypto`. Raw database inspection shows only unreadable ciphertext tokens (`iv:authTag:ciphertext`).
4. **User A ➔ User B Hard Isolation**:
   Cross-account access attempts are blocked directly at the database engine level (0 rows returned).

---

## ⚡ Quick Start & Execution

### 1. Database Setup (Supabase / PostgreSQL)
Execute the master consolidated SQL migration script in your Supabase SQL Editor or `psql` console:
```bash
wrindhaos-backend/migrations/000_wrindhaos_master_database_schema.sql
```

### 2. Run Backend API Server
```bash
cd wrindhaos-backend
npm install
npm start
```
- 📡 **REST API**: `http://localhost:5000`
- 🛠️ **Admin Portal**: `http://localhost:5000/admin`
- 📄 **OpenAPI Docs**: `http://localhost:5000/api-docs`

### 3. Run Flutter Application
```bash
flutter pub get
flutter run -d chrome  # or flutter run for Android/iOS
```

### 4. Run Automated Test Suites
```bash
cd wrindhaos-backend
node --test tests/zeroAdminAccess.test.js  # 16 Security Tests
node --test tests/backend.test.js          # 10 Functional Tests
```

---

## 📦 What to Push to GitHub

Pushed to GitHub:
- `lib/` (All Flutter dart source files)
- `pubspec.yaml`, `pubspec.lock`
- `serve.js`
- `wrindhaos-backend/` (All Express source code, controllers, routes, middleware, and SQL migrations)
- `wrindhaos-backend/package.json`, `wrindhaos-backend/package-lock.json`
- `.gitignore`
- `README.md`

Excluded from GitHub (via `.gitignore`):
- `**/node_modules/` (Reinstalled on server via `npm install`)
- `.env`, `.env.local` (Environment secret keys)
- `.dart_tool/`, `build/` (Generated build artifacts)
