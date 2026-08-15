-- =============================================================================
-- WRINDHAOS COMPLETE PRODUCTION DATABASE SCHEMA (POSTGRESQL / SUPABASE)
-- Migration Script: 003_complete_wrindhaos_schema.sql
-- Description: Complete Relational Schema aligning Frontend Application Modules
--              AND Super Admin Backoffice Management System Tables
-- =============================================================================

-- Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. USERS & PROFILES MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    display_name VARCHAR(100) DEFAULT 'Student User',
    focus_score INT DEFAULT 0 CHECK (focus_score BETWEEN 0 AND 100),
    active_streak INT DEFAULT 0 CHECK (active_streak >= 0),
    subscription_plan VARCHAR(20) DEFAULT 'FREE' CHECK (subscription_plan IN ('FREE', 'PREMIUM_MONTHLY', 'PREMIUM_YEARLY')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notification_settings (
    user_id UUID PRIMARY KEY REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    push_notifications_enabled BOOLEAN DEFAULT true,
    email_notifications_enabled BOOLEAN DEFAULT true,
    preferred_reminder_time TIME DEFAULT '08:00:00',
    habit_reminders_enabled BOOLEAN DEFAULT true,
    expense_alerts_enabled BOOLEAN DEFAULT true,
    study_reminders_enabled BOOLEAN DEFAULT true,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    referee_id UUID REFERENCES user_profiles(user_id) ON DELETE SET NULL,
    referral_code VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'EXPIRED')),
    reward_xp INT DEFAULT 100,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 2. HABITS, STREAKS & REWARDS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS habits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    frequency VARCHAR(20) DEFAULT 'DAILY' CHECK (frequency IN ('DAILY', 'WEEKDAYS', 'WEEKENDS', 'CUSTOM')),
    preferred_time TIME DEFAULT '08:00:00',
    icon_name VARCHAR(50) DEFAULT 'auto_awesome_rounded',
    color_hex VARCHAR(10) DEFAULT '#0D5CE5',
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS habit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    completed_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_habit_log_per_day UNIQUE (habit_id, completed_date)
);

CREATE TABLE IF NOT EXISTS habit_streaks (
    habit_id UUID PRIMARY KEY REFERENCES habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    current_streak_days INT DEFAULT 0,
    longest_streak_days INT DEFAULT 0,
    last_completed_date DATE
);

CREATE TABLE IF NOT EXISTS habit_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    reward_title VARCHAR(100) NOT NULL,
    badge_type VARCHAR(50) NOT NULL CHECK (badge_type IN ('EARLY_BIRD', 'ON_FIRE', 'CONSISTENT_MASTER')),
    badge_icon VARCHAR(50) NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 3. EXPENSES & FINANCIAL HEALTH MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS monthly_budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    budget_month DATE NOT NULL,
    total_budget_amount NUMERIC(12, 2) NOT NULL DEFAULT 10000.00,
    currency VARCHAR(10) DEFAULT 'INR',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_monthly_budget UNIQUE (user_id, budget_month)
);

CREATE TABLE IF NOT EXISTS expense_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    category_name VARCHAR(50) NOT NULL,
    icon_name VARCHAR(50) DEFAULT 'category',
    color_hex VARCHAR(10) DEFAULT '#0D5CE5'
);

CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    category_id UUID REFERENCES expense_categories(id) ON DELETE SET NULL,
    category_name VARCHAR(50) NOT NULL,
    title VARCHAR(150) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method VARCHAR(30) DEFAULT 'UPI',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 4. GOALS HIERARCHY & MILESTONES MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS goals_hierarchy (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    goal_title VARCHAR(150) NOT NULL,
    pyramid_level VARCHAR(20) NOT NULL CHECK (pyramid_level IN ('SHORT_TERM', 'MEDIUM_TERM', 'LONG_TERM')),
    target_date DATE,
    progress_percentage INT DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    goal_id UUID REFERENCES goals_hierarchy(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'CAREER',
    target_date DATE,
    status VARCHAR(20) DEFAULT 'NOT_STARTED' CHECK (status IN ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED')),
    completion_percentage INT DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 5. EISENHOWER MATRIX & PRIORITY MATRIX MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS eisenhower_matrix_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    quadrant VARCHAR(20) NOT NULL CHECK (quadrant IN ('DO_FIRST', 'SCHEDULE', 'DELEGATE', 'DONT_DO')),
    due_date DATE,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS priority_matrix_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    priority_level VARCHAR(20) NOT NULL CHECK (priority_level IN ('HIGH_PRIORITY', 'MEDIUM_PRIORITY', 'LOW_PRIORITY')),
    due_date DATE,
    preferred_time TIME,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 6. JOURNAL MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    body_content TEXT NOT NULL,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    mood_rating VARCHAR(20) DEFAULT 'NEUTRAL' CHECK (mood_rating IN ('GREAT', 'GOOD', 'NEUTRAL', 'STRESSED', 'LOW')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 7. CAREER DASHBOARD & LEVEL-WISE ROADMAP MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS career_levels (
    level_number INT PRIMARY KEY CHECK (level_number >= 0),
    level_title VARCHAR(100) NOT NULL,
    xp_required INT NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS career_nodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    node_title VARCHAR(150) NOT NULL,
    level_number INT NOT NULL REFERENCES career_levels(level_number) ON DELETE CASCADE,
    node_order INT NOT NULL DEFAULT 1,
    description TEXT,
    skills_unlocked TEXT,
    status VARCHAR(20) DEFAULT 'LOCKED' CHECK (status IN ('LOCKED', 'AVAILABLE', 'COMPLETED')),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 8. ACADEMIC MODULE (SUBJECTS, UNITS, TOPICS & STUDY SESSIONS)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subjects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    subject_name VARCHAR(100) NOT NULL,
    subject_code VARCHAR(20),
    color_hex VARCHAR(10) DEFAULT '#0D5CE5',
    mastery_percentage INT DEFAULT 0 CHECK (mastery_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    unit_title VARCHAR(150) NOT NULL,
    unit_order INT DEFAULT 1,
    description TEXT,
    mastery_percentage INT DEFAULT 0 CHECK (mastery_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    topic_title VARCHAR(150) NOT NULL,
    topic_order INT DEFAULT 1,
    resource_url TEXT,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    focus_xp_earned INT DEFAULT 0,
    session_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 9. TIME TABLE & CALENDAR SCHEDULE MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS time_table_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Monday, 7=Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    activity_title VARCHAR(150) NOT NULL,
    activity_type VARCHAR(20) DEFAULT 'STUDY' CHECK (activity_type IN ('STUDY', 'WORK', 'BREAK', 'REVISION')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS calendar_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    start_time TIME NOT NULL DEFAULT '09:00:00',
    end_time TIME NOT NULL DEFAULT '10:30:00',
    location VARCHAR(150) DEFAULT 'Workspace',
    event_type VARCHAR(30) DEFAULT 'FOCUS_SESSION' CHECK (event_type IN ('FOCUS_SESSION', 'MEETING', 'TASK', 'STUDY')),
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 10. TO-DO TASKS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS todo_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) DEFAULT 'Studies',
    due_date DATE,
    preferred_time TIME DEFAULT '08:00:00',
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 11. ANALYTICS & DAILY PERFORMANCE TRACKING MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_daily_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    record_date DATE NOT NULL DEFAULT CURRENT_DATE,
    tasks_completed_count INT DEFAULT 0,
    habits_completed_count INT DEFAULT 0,
    study_duration_minutes INT DEFAULT 0,
    total_expense_amount NUMERIC(12, 2) DEFAULT 0.00,
    daily_focus_score INT DEFAULT 0,
    CONSTRAINT unique_user_daily_analytic UNIQUE (user_id, record_date)
);

-- -----------------------------------------------------------------------------
-- 12. PAYMENTS & GOOGLE PLAY SUBSCRIPTIONS MODULE
-- -----------------------------------------------------------------------------
-- STRICT MANDATE: Google Play Billing ONLY. No Razorpay, Stripe, or PayPal.
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    package_name VARCHAR(150) NOT NULL DEFAULT 'com.wrindhaos.productivity',
    subscription_id VARCHAR(100) NOT NULL, -- Google Play Subscription Product ID
    purchase_token TEXT NOT NULL UNIQUE,     -- Google Play Purchase Token
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CANCELED', 'EXPIRED', 'PAUSED')),
    auto_renewing BOOLEAN DEFAULT true,
    expiry_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    google_order_id VARCHAR(100) NOT NULL UNIQUE,
    amount_micros BIGINT NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    payment_state VARCHAR(30) DEFAULT 'PAYMENT_RECEIVED',
    purchase_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 13. SUPER ADMIN & BACKOFFICE MANAGEMENT MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'SUPPORT_AGENT' CHECK (role IN ('SUPER_ADMIN', 'SUPPORT_AGENT', 'FINANCE_ADMIN', 'MODERATOR')),
    permissions JSONB NOT NULL DEFAULT '["READ_USERS"]',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed default Super Admin account
INSERT INTO admin_users (email, full_name, role, permissions)
VALUES (
    'admin@wrindhaos.com',
    'WrindhaOS System Administrator',
    'SUPER_ADMIN',
    '["ALL"]'
)
ON CONFLICT (email) DO NOTHING;

CREATE TABLE IF NOT EXISTS admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,
    target_user_id UUID REFERENCES user_profiles(user_id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL, -- PLAN_OVERRIDE | USER_BAN | USER_UNBAN | FEATURE_FLAG_UPDATE | SYSTEM_BROADCAST
    details JSONB,
    ip_address VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_moderation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    is_banned BOOLEAN NOT NULL DEFAULT TRUE,
    ban_reason TEXT,
    banned_by UUID REFERENCES admin_users(id),
    banned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    unbanned_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS app_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES admin_users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO app_settings (key, value, description)
VALUES 
    ('maintenance_mode', '{"enabled": false, "message": "WrindhaOS is undergoing scheduled maintenance."}', 'Global system maintenance toggle'),
    ('system_broadcast', '{"enabled": false, "text": "Welcome to WrindhaOS!"}', 'System-wide announcement banner'),
    ('max_free_habits', '{"limit": 2}', 'Max habits allowed for free plan'),
    ('max_free_subjects', '{"limit": 2}', 'Max subjects allowed for free plan')
ON CONFLICT (key) DO NOTHING;

CREATE TABLE IF NOT EXISTS analytics_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    snapshot_date DATE UNIQUE NOT NULL DEFAULT CURRENT_DATE,
    total_users INT NOT NULL DEFAULT 0,
    free_users INT NOT NULL DEFAULT 0,
    premium_users INT NOT NULL DEFAULT 0,
    active_subscriptions INT NOT NULL DEFAULT 0,
    mrr_estimate_inr NUMERIC(12, 2) DEFAULT 0.00,
    dau_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- INDEXES FOR MAXIMUM QUERY PERFORMANCE
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits(user_id);
CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON habit_logs(user_id, completed_date);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, expense_date);
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date ON calendar_events(user_id, event_date);
CREATE INDEX IF NOT EXISTS idx_todo_tasks_user ON todo_tasks(user_id, is_completed);
CREATE INDEX IF NOT EXISTS idx_subjects_user ON subjects(user_id);
CREATE INDEX IF NOT EXISTS idx_units_subject ON units(subject_id);
CREATE INDEX IF NOT EXISTS idx_topics_unit ON topics(unit_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_admin_role ON admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_audit_target ON admin_audit_logs(target_user_id);
CREATE INDEX IF NOT EXISTS idx_moderation_user ON user_moderation(user_id);
