# 🗄️ WrindhaOS Database Schema & API Mappings Reference

This document provides a complete authoritative reference for the **Supabase PostgreSQL Database Schema**, active database tables, canonical column definitions, and deferred password staging mechanisms in WrindhaOS.

---

## 📋 1. Active Database Tables & Column Mappings

### A. User Profiles (`public.profiles`)
Stores user accounts, display metadata, authentication hashes, and subscription tiers.

| Column Name | Data Type | Key Type / Constraint | Description & Purpose |
|---|---|---|---|
| `id` | `UUID` | Primary Key | Canonical user UUID identifier |
| `username` | `TEXT` | Unique, Not Null | Clean lowercase username string |
| `email` | `TEXT` | Unique, Not Null | Clean lowercase registered email address |
| `password_hash` | `TEXT` | Not Null | Primary active PBKDF2 SHA-512 password hash (`salt:hash`) |
| **`new_password`** | **`TEXT`** | **Nullable** | **Staged PBKDF2 password hash created during Forgot Password reset** |
| `display_name` | `TEXT` | Nullable | User display full name |
| `phone_number` | `TEXT` | Nullable | User contact phone number |
| `avatar_url` | `TEXT` | Nullable | Profile picture URL |
| `is_premium` | `BOOLEAN` | Default `false` | Pro subscription flag |
| `subscription_plan`| `TEXT` | Default `'FREE'` | Active plan tier (`FREE` / `PRO` / `PREMIUM`) |
| `focus_score` | `INT` | Default `85` | User productivity score |
| `active_streak` | `INT` | Default `1` | Active consecutive activity streak |
| `referral_code` | `TEXT` | Unique | User invite referral code (`WRINDHA_XXXXXX`) |
| `is_email_verified`| `BOOLEAN` | Default `false` | Email verification flag |
| `fcm_device_token` | `TEXT` | Nullable | Push notification token |
| `created_at` | `TIMESTAMPTZ`| Default `NOW()` | Profile creation timestamp |
| `updated_at` | `TIMESTAMPTZ`| Default `NOW()` | Profile last updated timestamp |

---

### B. Habits (`public.habits`)
Stores habit tracking definitions.

| Column Name | Data Type | Key Type / Constraint | Description |
|---|---|---|---|
| `id` | `UUID` | Primary Key | Habit UUID |
| `user_id` | `UUID` | Foreign Key (`profiles.id`) | Owner user UUID |
| `title` | `TEXT` | Not Null | Habit title |
| `description` | `TEXT` | Nullable | Optional description |
| `category` | `TEXT` | Default `'General'` | Category (`Health`, `Studies`, etc.) |
| `frequency` | `TEXT` | Default `'daily'` | Frequency (`daily`, `weekly`, `monthly`) |
| `icon_name` | `TEXT` | Default `'repeat'` | Icon identifier |
| `color_hex` | `TEXT` | Default `'#10B981'` | Theme hex color string |
| `status` | `TEXT` | Default `'active'` | Habit status (`active` / `archived`) |
| `streak_count` | `INT` | Default `0` | Active streak integer |
| `best_streak` | `INT` | Default `0` | Maximum streak achieved |
| `created_at` | `TIMESTAMPTZ`| Default `NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ`| Default `NOW()` | Update timestamp |

---

### C. Habit Completion Logs (`public.habit_logs`)
Stores individual daily habit completions.

| Column Name | Data Type | Key Type / Constraint | Description |
|---|---|---|---|
| `id` | `UUID` | Primary Key | Log record UUID |
| `habit_id` | `UUID` | Foreign Key (`habits.id`) | Associated habit UUID |
| `user_id` | `UUID` | Foreign Key (`profiles.id`) | Associated user UUID |
| `completion_date` | `TEXT` | Not Null | Date string (`YYYY-MM-DD`) |
| `status` | `TEXT` | Default `'completed'` | Completion status |
| `notes` | `TEXT` | Nullable | Optional completion note |
| `completed_at` | `TIMESTAMPTZ`| Default `NOW()` | Timestamp of completion |

---

### D. Tasks & To-Dos (`public.tasks`)
Stores to-dos, priorities, and Eisenhower matrix assignments.

| Column Name | Data Type | Key Type / Constraint | Description |
|---|---|---|---|
| `id` | `UUID` | Primary Key | Task UUID |
| `user_id` | `UUID` | Foreign Key (`profiles.id`) | Owner user UUID |
| `title` | `TEXT` | Not Null | Task title |
| `description` | `TEXT` | Nullable | Optional task description |
| `category` | `TEXT` | Default `'Studies'` | Category |
| `priority` | `INT` | Default `1` | Priority rating (1 - 4) |
| `quadrant` | `TEXT` | Default `'q1_do_first'` | Eisenhower quadrant (`q1` to `q4`) |
| `is_completed` | `BOOLEAN` | Default `false` | Task completion flag |
| `completed_at` | `TIMESTAMPTZ`| Nullable | Timestamp when completed |
| `due_at` | `TIMESTAMPTZ`| Default `NOW()` | Target deadline timestamp |

---

### E. Expenses & Financial Logs (`public.expenses`)
Stores financial transactions and income/expense records.

| Column Name | Data Type | Key Type / Constraint | Description |
|---|---|---|---|
| `id` | `UUID` | Primary Key | Expense UUID |
| `user_id` | `UUID` | Foreign Key (`profiles.id`) | Owner user UUID |
| `title` | `TEXT` | Not Null | Expense description/title |
| `amount` | `NUMERIC` | Not Null | Monetary amount |
| `category` | `TEXT` | Default `'General'` | Budget category |
| `transaction_type`| `TEXT` | Default `'expense'` | Transaction type (`expense` / `income`) |
| `payment_method` | `TEXT` | Default `'UPI'` | Payment method |
| `occurred_at` | `TIMESTAMPTZ`| Default `NOW()` | Timestamp of transaction |

---

### F. Subjects & Study Planner (`public.subjects`)
Stores academic subjects.

| Column Name | Data Type | Key Type / Constraint | Description |
|---|---|---|---|
| `id` | `UUID` | Primary Key | Subject UUID |
| `user_id` | `UUID` | Foreign Key (`profiles.id`) | Owner user UUID |
| `name` | `TEXT` | Not Null | Subject name |
| `code` | `TEXT` | Nullable | Subject code (e.g. `CS101`) |
| `instructor` | `TEXT` | Nullable | Professor / Instructor name |
| `color_hex` | `TEXT` | Default `'#0D5CE5'` | Subject theme color |
| `credits` | `INT` | Default `3` | Subject credit hours |

---

### G. Goals (`public.goals`)
Stores short-term, medium-term, and long-term targets.

| Column Name | Data Type | Key Type / Constraint | Description |
|---|---|---|---|
| `id` | `UUID` | Primary Key | Goal UUID |
| `user_id` | `UUID` | Foreign Key (`profiles.id`) | Owner user UUID |
| `title` | `TEXT` | Not Null | Goal title |
| `description` | `TEXT` | Nullable | Purpose / Description |
| `tier` | `TEXT` | Default `'short'` | Timeframe tier (`short` / `medium` / `long`) |
| `section` | `TEXT` | Default `'GOAL'` | Target section |
| `category` | `TEXT` | Default `'General'` | Category |
| `target_date` | `TIMESTAMPTZ`| Nullable | Deadline timestamp |
| `is_completed` | `BOOLEAN` | Default `false` | Goal completion status |

---

### H. Calendar Events (`public.calendar_events`)
Stores calendar schedule events.

| Column Name | Data Type | Key Type / Constraint | Description |
|---|---|---|---|
| `id` | `UUID` | Primary Key | Event UUID |
| `user_id` | `UUID` | Foreign Key (`profiles.id`) | Owner user UUID |
| `title` | `TEXT` | Not Null | Event title |
| `description` | `TEXT` | Nullable | Event description |
| `event_date` | `TEXT` | Not Null | Event date string (`YYYY-MM-DD`) |
| `start_time` | `TEXT` | Default `'10:00:00'` | Start time string (`HH:mm:ss`) |
| `end_time` | `TEXT` | Default `'11:00:00'` | End time string (`HH:mm:ss`) |
| `category` | `TEXT` | Default `'General'` | Event category |
| `location` | `TEXT` | Nullable | Event location |
| `is_all_day` | `BOOLEAN` | Default `false` | All-day event flag |

---

### I. Journal Entries (`public.journal_entries`)
Stores private reflection and mood logs.

| Column Name | Data Type | Key Type / Constraint | Description |
|---|---|---|---|
| `id` | `UUID` | Primary Key | Journal entry UUID |
| `user_id` | `UUID` | Foreign Key (`profiles.id`) | Owner user UUID |
| `title` | `TEXT` | Default `'Journal Entry'` | Entry title |
| `content` | `TEXT` | Not Null | Body content text |
| `mood` | `TEXT` | Default `'neutral'` | Recorded mood |
| `entry_date` | `TEXT` | Not Null | Entry date string (`YYYY-MM-DD`) |

---

### J. Subscriptions & Billing (`public.subscriptions`)
Stores user billing provider details and Pro plan statuses.

| Column Name | Data Type | Key Type / Constraint | Description |
|---|---|---|---|
| `id` | `UUID` | Primary Key | Subscription UUID |
| `user_id` | `UUID` | Foreign Key (`profiles.id`) | Associated user UUID |
| `plan` | `TEXT` | Default `'free'` | Plan tier (`free` / `pro` / `premium`) |
| `status` | `TEXT` | Default `'active'` | Subscription status |
| `payment_provider`| `TEXT` | Default `'NONE'` | Payment provider (`GOOGLE_PLAY` / `NONE`) |
| `started_at` | `TIMESTAMPTZ`| Default `NOW()` | Subscription start timestamp |
| `expires_at` | `TIMESTAMPTZ`| Nullable | Expiration timestamp |

---

## 🚫 2. Permanently Dropped Redundant Tables & Columns

### Dropped Tables:
- `habit_completions` *(Consolidated to `habit_logs`)*
- `goals_hierarchy` *(Replaced by `goals`)*
- `career_roadmap_nodes` *(Replaced by `career_roadmap`)*
- `subject_units` & `subject_topics` *(Embedded dynamically)*
- `fcm_tokens` & `notifications` *(Consolidated to `profiles.fcm_device_token`)*

### Dropped Columns:
- `profiles`: `name`, `full_name`, `contact`, `profile_image`, `user_id`
- `habits`: `color`, `streak_day`
- `expenses`: `expense_date`, `date`
- `subjects`: `subject_name`, `color`
- `subscriptions`: `billing_provider`
- `tasks`: `due_date`
- `journal_entries`: `date`, `encryption_version`, `key_id`
- `calendar_events`: `date`

---

## 🔒 3. Deferred Password Promotion Flow

1. **Forgot Password Reset**: When a user resets their password, the new PBKDF2 hash is stored in `profiles.new_password`. `profiles.password_hash` remains unchanged.
2. **First Login With New Password**:
   - Backend tests `password` against `profiles.password_hash` (fails).
   - Backend tests `password` against `profiles.new_password` (succeeds).
   - Backend updates `profiles.password_hash = profiles.new_password` and sets `profiles.new_password = NULL`.
   - Backend syncs updated hash to Supabase Auth Admin.
