import { LegalDocument, WebsiteSettings } from '../types';

export const INITIAL_WEBSITE_SETTINGS: WebsiteSettings = {
  id: 'global_website_settings',
  general: {
    website_name: 'WrindhaOS',
    website_url: 'https://wrindhaos.in',
    short_description: 'The personal operating system for habit mastery, routine tracking, and career roadmaps.',
    support_email: 'support@wrindhaos.in',
    contact_phone: '+91 800-974-6342',
  },
  homepage: {
    hero_headline: 'Your Personal Operating System for Progress.',
    hero_description: 'Track habits, manage daily routines, monitor expenses, and navigate long-term career roadmaps in one high-performance personal workspace.',
    primary_cta_text: 'Get WrindhaOS',
    primary_cta_url: 'https://wrindhaos.in/download',
    secondary_cta_text: 'Explore Roadmaps',
    secondary_cta_url: 'https://wrindhaos.in/roadmaps',
  },
  app_links: {
    google_play_url: '', // Unconfigured initially until Google Play listing is approved
    android_apk_url: 'https://wrindhaos.in/downloads/wrindhaos-latest.apk',
    web_app_url: 'https://app.wrindhaos.in',
  },
  contact: {
    support_email: 'support@wrindhaos.in',
    business_email: 'contact@wrindhaos.in',
    grievance_email: 'grievance-officer@wrindhaos.in',
    contact_page_url: '/contact',
    physical_address: 'WrindhaOS Technologies India Pvt Ltd, Bengaluru, Karnataka 560100, India',
  },
  updated_at: new Date().toISOString(),
  updated_by: 'adm-001',
};

export const INITIAL_LEGAL_DOCUMENTS: LegalDocument[] = [
  {
    id: 'legal-001',
    slug: 'privacy-policy',
    title: 'Privacy Policy',
    description: 'Details what student and user information WrindhaOS collects, processes, and protects.',
    status: 'PUBLISHED',
    public_url: '/privacy-policy',
    version: '1.2.0',
    content: `# WrindhaOS Privacy Policy

**Effective Date:** August 15, 2026  
**Last Updated:** August 15, 2026  
**Entity:** WrindhaOS Technologies India Pvt Ltd

---

## 1. Introduction
WrindhaOS ("we", "us", or "our") operates the WrindhaOS mobile application, web applications, and website at https://wrindhaos.in. We are committed to protecting the privacy and personal data of students, educators, and users who access our services.

This Privacy Policy explains what personal information we collect, why we collect it, how it is used and secured, and your legal rights regarding your data.

## 2. Information We Collect
We only collect data strictly necessary to provide and enhance your student operating system experience:

* **Account Information:** Name, email address, password hash, phone number (optional), and login method (e.g., Google OAuth or email).
* **Academic & Profile Data:** School/college, major, academic board/exam preferences (e.g., CBSE, ICSE, JEE), and target graduation year.
* **Productivity & Study Data:** Study goals, daily task records, Pomodoro session timers, habit completions, and syllabus progress tracking.
* **Technical & Diagnostic Data:** Device hardware model, operating system version, app version, IP address, and anonymized crash logs.

## 3. How We Use Your Data
We process your information exclusively for the following functional purposes:
* Providing personalized study plans and syllabus navigation.
* Authenticating your account securely across devices.
* Delivering push notifications and study reminders (when opted in).
* Processing subscription upgrades and verifying active license entitlements.
* Investigating security incidents, fraud prevention, and platform stability.

**Data Selling Prohibition:** We do NOT sell, rent, or trade your personal information to third-party data brokers or advertisers under any circumstances.

## 4. Data Security & Storage
* All communications between your device and our servers use TLS 1.3 encryption.
* Sensitive user data stored at rest is encrypted using industry-standard AES-256 protocols.
* Access to operational databases is restricted to authorized engineers under strict least-privilege administrative controls.

## 5. Account & Data Deletion
You retain complete ownership of your personal data. You may request permanent deletion of your account and associated study records at any time directly through the app settings or via our dedicated [Account Deletion Portal](/account-deletion).

## 6. Grievance Officer & Contact
If you have questions, concerns, or privacy grievances, please contact our Grievance Redressal Officer at:
* **Email:** grievance-officer@wrindhaos.in
* **Support:** support@wrindhaos.in`,
    created_at: new Date(Date.now() - 30 * 86400000).toISOString(),
    updated_at: new Date(Date.now() - 2 * 86400000).toISOString(),
    updated_by: 'adm-001',
    updated_by_email: 'admin@wrindhaos.com',
  },
  {
    id: 'legal-002',
    slug: 'terms',
    title: 'Terms & Conditions',
    description: 'Terms governing the access, subscription, and lawful use of WrindhaOS.',
    status: 'PUBLISHED',
    public_url: '/terms',
    version: '1.1.0',
    content: `# WrindhaOS Terms & Conditions

**Effective Date:** August 15, 2026  
**Last Updated:** August 15, 2026  
**Entity:** WrindhaOS Technologies India Pvt Ltd

---

## 1. Acceptance of Terms
By downloading, creating an account, or using WrindhaOS, you agree to be bound by these Terms & Conditions. If you do not agree, you must not use our software or services.

## 2. Eligibility & Student Accounts
* You must provide accurate and verifiable registration information.
* You are responsible for safeguarding your account credentials.
* Users under 18 years of age must have parental or legal guardian consent to subscribe to paid plans.

## 3. Scope of Services & Educational Disclaimer
WrindhaOS provides organizational tools, academic curriculums, and career milestone trackers designed to assist students in structuring their self-study and learning habits.

**Disclaimer:** WrindhaOS is a self-directed productivity tool. We make no representations or guarantees regarding specific exam results, academic scores, admissions, or employment outcomes.

## 4. Subscriptions & Billing
* **Free Plan:** Provides foundational productivity tools at ₹0 cost.
* **Pro Plan:** Provides complete academic roadmaps, unlimited habit tracking, and career tools. Subscriptions are billed at the advertised recurring rate (e.g., ₹49/month) or as specified at checkout.
* Billing cycles renew automatically unless cancelled prior to the renewal date.

## 5. Prohibited Conduct
You agree not to:
* Reverse engineer, decompile, or copy the software or proprietary content.
* Circumvent platform access restrictions or subscription checks.
* Use the service for any illegal, abusive, or unauthorized purposes.

## 6. Termination & Suspension
We reserve the right to suspend or terminate accounts that violate these terms, engage in security tampering, or abuse the platform infrastructure.

## 7. Governing Law
These terms are governed by the laws of India, and any disputes shall be subject to the exclusive jurisdiction of the courts in Bengaluru, India.`,
    created_at: new Date(Date.now() - 30 * 86400000).toISOString(),
    updated_at: new Date(Date.now() - 3 * 86400000).toISOString(),
    updated_by: 'adm-001',
    updated_by_email: 'admin@wrindhaos.com',
  },
  {
    id: 'legal-003',
    slug: 'refund-policy',
    title: 'Refund & Cancellation Policy',
    description: 'Outlines subscription cancellation workflows, trial terms, and refund eligibility.',
    status: 'PUBLISHED',
    public_url: '/refund-policy',
    version: '1.0.0',
    content: `# WrindhaOS Refund & Cancellation Policy

**Effective Date:** August 15, 2026  
**Last Updated:** August 15, 2026

---

## 1. Subscription Cancellation
You may cancel your WrindhaOS Pro subscription at any time:
* Through the mobile app: **Settings → Account → Manage Subscription → Cancel Subscription**.
* By contacting support at: **support@wrindhaos.in**.

When you cancel, your Pro benefits remain active until the end of your current paid billing cycle. You will not be charged for subsequent billing intervals.

## 2. 7-Day Free Trial Terms
If you enroll in a 7-day Pro free trial, you will not be charged if you cancel before the 7-day trial period expires. If you do not cancel before the trial concludes, your subscription will automatically transition to the monthly billing plan (₹49/month).

## 3. Refund Eligibility
Because WrindhaOS provides immediate digital access upon subscription activation:
* **Standard Policy:** Monthly subscription charges are generally non-refundable once the billing cycle begins.
* **Technical Errors & Duplicate Billing:** If you experience duplicate billing or technical errors preventing service access, please notify support within 7 days of the transaction for a full reversal.
* **Statutory Rights:** Nothing in this policy limits statutory refund rights mandated by consumer protection regulations in your jurisdiction.

## 4. Refund Processing Time
Approved refunds are credited to the original payment method within 5 to 7 business days depending on your bank or payment gateway provider.`,
    created_at: new Date(Date.now() - 25 * 86400000).toISOString(),
    updated_at: new Date(Date.now() - 5 * 86400000).toISOString(),
    updated_by: 'adm-001',
    updated_by_email: 'admin@wrindhaos.com',
  },
  {
    id: 'legal-004',
    slug: 'account-deletion',
    title: 'Account Deletion Request',
    description: 'Instructions and compliance protocol for user data and account purging.',
    status: 'PUBLISHED',
    public_url: '/account-deletion',
    version: '1.0.0',
    content: `# WrindhaOS Account & Data Deletion

**Effective Date:** August 15, 2026  
**Last Updated:** August 15, 2026

---

## How to Delete Your WrindhaOS Account

At WrindhaOS, we respect your right to manage and permanently delete your personal information and student account.

### Method 1: Self-Service in Mobile App (Instant)
1. Open the **WrindhaOS** application on your device.
2. Navigate to **Profile → Settings → Security & Account**.
3. Tap **Delete Account** and confirm your password.
4. Your account is immediately scheduled for permanent data purging.

### Method 2: Web Deletion Request Form / Email
If you no longer have access to the mobile application, you may submit a deletion request:
* **Send an email to:** support@wrindhaos.in
* **Subject line:** "Account Deletion Request - [Your Registered Email]"
* **Include:** Your full name and registered email address.

Our security team will verify identity ownership and process the deletion within 48 business hours.

---

## What Happens When Your Account is Deleted
* **Permanently Purged:** Your name, email, phone number, study schedules, custom notes, curriculum progress, and habit streaks.
* **Subscriptions:** Any active recurring billing is immediately halted.
* **Retention Exceptions:** Aggregated, non-identifiable technical logs and statutory tax/payment transaction records required by financial laws are retained for legally mandated durations only.`,
    created_at: new Date(Date.now() - 25 * 86400000).toISOString(),
    updated_at: new Date(Date.now() - 4 * 86400000).toISOString(),
    updated_by: 'adm-001',
    updated_by_email: 'admin@wrindhaos.com',
  },
  {
    id: 'legal-005',
    slug: 'contact',
    title: 'Contact & Grievance Redressal',
    description: 'Official communication channels, physical office address, and Grievance Officer details.',
    status: 'PUBLISHED',
    public_url: '/contact',
    version: '1.0.0',
    content: `# Contact Us & Grievance Redressal

**Entity:** WrindhaOS Technologies India Pvt Ltd  
**Website:** https://wrindhaos.in

---

## General Support & Help
* **Customer & Student Support:** support@wrindhaos.in
* **Business & Partnership Enquiries:** contact@wrindhaos.in
* **Operating Hours:** Monday to Friday, 09:30 AM – 06:30 PM IST
* **Response Time:** We strive to respond to all student support inquiries within 24 to 48 business hours.

---

## Grievance Redressal Officer
In accordance with Information Technology rules and applicable consumer protection guidelines, the designated Grievance Officer for WrindhaOS is:

* **Designation:** Chief Information & Compliance Officer
* **Email:** grievance-officer@wrindhaos.in
* **Corporate Address:**  
  WrindhaOS Technologies India Pvt Ltd  
  Outer Ring Road, Bellandur,  
  Bengaluru, Karnataka 560100, India

### Grievance Escalation Process
1. Email your grievance with complete account details and a clear description of the issue.
2. A formal ticket reference number will be acknowledged within 24 hours.
3. Full resolution will be provided within 15 working days from receipt of the complaint.`,
    created_at: new Date(Date.now() - 25 * 86400000).toISOString(),
    updated_at: new Date(Date.now() - 4 * 86400000).toISOString(),
    updated_by: 'adm-001',
    updated_by_email: 'admin@wrindhaos.com',
  },
  {
    id: 'legal-006',
    slug: 'cookies',
    title: 'Cookie & Analytics Disclosure',
    description: 'Clarifies session cookies, telemetry collection, and local storage usage.',
    status: 'PUBLISHED',
    public_url: '/cookies',
    version: '1.0.0',
    content: `# WrindhaOS Cookie & Analytics Disclosure

**Effective Date:** August 15, 2026  
**Last Updated:** August 15, 2026

---

## 1. What Are Cookies & Local Storage
Cookies and local browser storage are small text files or key-value entries stored on your browser or device that enable our services to remember your active session, preferences, and security state.

## 2. Cookies We Use
* **Strictly Necessary Cookies:** Essential for secure user authentication, maintaining active session tokens, and load balancing across our infrastructure.
* **Preference Storage:** Remembers your UI theme (Light/Dark mode), subject filters, and layout preferences locally on your device.
* **Performance & Telemetry:** Anonymized metrics to evaluate app load speed, screen transition latency, and system crash diagnostics.

## 3. Third-Party Analytics
We do not permit third-party advertising cookies or cross-site tracking scripts on WrindhaOS. Telemetry is collected purely for infrastructure reliability and product performance.

## 4. Managing Cookies
You can control or clear cookies in your browser settings. Please note that disabling essential session cookies may prevent authentication with WrindhaOS.`,
    created_at: new Date(Date.now() - 20 * 86400000).toISOString(),
    updated_at: new Date(Date.now() - 5 * 86400000).toISOString(),
    updated_by: 'adm-001',
    updated_by_email: 'admin@wrindhaos.com',
  },
  {
    id: 'legal-007',
    slug: 'copyright',
    title: 'Copyright & Intellectual Property Notice',
    description: 'Trademarks, software copyright, and proprietary content protection notice.',
    status: 'PUBLISHED',
    public_url: '/copyright',
    version: '1.0.0',
    content: `# Copyright & Intellectual Property Notice

**Copyright © 2026 WrindhaOS Technologies India Pvt Ltd. All rights reserved.**

---

## 1. Proprietary Rights
The WrindhaOS software application, design layouts, graphical assets, logo marks, curriculum structuring algorithms, milestone frameworks, and software code are the proprietary intellectual property of WrindhaOS Technologies India Pvt Ltd.

## 2. Trademarks
"WrindhaOS", the WrindhaOS logo, and associated brand badges are trademarks of WrindhaOS Technologies India Pvt Ltd. Unauthorized use of these marks without explicit written consent is strictly prohibited.

## 3. Curriculum Content
Curriculum structures, syllabus breakdowns, and career milestones curated within the application are organized for educational guidance. All third-party examination names (such as CBSE, ICSE, JEE, NEET, etc.) are the property of their respective trademark holders and are referenced for identification and informational purposes only.

## 4. Infringement Claims
If you believe that any material available on WrindhaOS infringes upon your copyright or intellectual property rights, please send formal notice to **contact@wrindhaos.in** with complete ownership documentation.`,
    created_at: new Date(Date.now() - 20 * 86400000).toISOString(),
    updated_at: new Date(Date.now() - 5 * 86400000).toISOString(),
    updated_by: 'adm-001',
    updated_by_email: 'admin@wrindhaos.com',
  },
];
