-- =============================================================================
-- WRINDHAOS ALL-IN-ONE MASTER PRODUCTION DATABASE SCHEMA (POSTGRESQL / SUPABASE)
-- File: 000_wrindhaos_master_database_schema.sql
-- Description: Consolidated Master Database Schema incorporating all 15+ Product
--              Feature Modules, Google Play Billing, Super Admin Backoffice Portal,
--              Zero-Admin-Access RLS Owner Isolation, and Developer pgcrypto AES-256.
-- =============================================================================

-- Enable Cryptographic & UUID Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. USERS, PROFILES & AUTHENTICATION IDENTITIES MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(255) DEFAULT 'Student User',
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(50) UNIQUE,
    profile_image TEXT,
    subscription_plan VARCHAR(50) NOT NULL DEFAULT 'FREE', -- FREE | PREMIUM
    subscription_status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | CANCELLED | EXPIRED | SUSPENDED
    ads_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    display_name VARCHAR(100) DEFAULT 'Student User',
    focus_score INT DEFAULT 0 CHECK (focus_score BETWEEN 0 AND 100),
    active_streak INT DEFAULT 0 CHECK (active_streak >= 0),
    subscription_plan VARCHAR(20) DEFAULT 'FREE' CHECK (subscription_plan IN ('FREE', 'PREMIUM_MONTHLY', 'PREMIUM_YEARLY')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_auth_identities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL, -- email | phone | google
    provider_user_id VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_provider_identity UNIQUE(provider, provider_user_id)
);

CREATE TABLE IF NOT EXISTS public.notification_settings (
    user_id UUID PRIMARY KEY REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    push_notifications_enabled BOOLEAN DEFAULT true,
    email_notifications_enabled BOOLEAN DEFAULT true,
    preferred_reminder_time TIME DEFAULT '08:00:00',
    habit_reminders_enabled BOOLEAN DEFAULT true,
    expense_alerts_enabled BOOLEAN DEFAULT true,
    study_reminders_enabled BOOLEAN DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    referee_id UUID REFERENCES public.user_profiles(user_id) ON DELETE SET NULL,
    referral_code VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'EXPIRED')),
    reward_xp INT DEFAULT 100,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 2. HABITS, STREAKS & REWARDS MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    frequency VARCHAR(50) DEFAULT 'DAILY' CHECK (frequency IN ('DAILY', 'WEEKDAYS', 'WEEKENDS', 'CUSTOM')),
    preferred_time TIME DEFAULT '08:00:00',
    icon_name VARCHAR(50) DEFAULT 'auto_awesome_rounded',
    color_hex VARCHAR(10) DEFAULT '#0D5CE5',
    target_days INT DEFAULT 7,
    current_streak INT DEFAULT 0,
    is_completed_today BOOLEAN NOT NULL DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.habit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    completed_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_habit_log_per_day UNIQUE (habit_id, completed_date)
);

CREATE TABLE IF NOT EXISTS public.habit_streaks (
    habit_id UUID PRIMARY KEY REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    current_streak_days INT DEFAULT 0,
    longest_streak_days INT DEFAULT 0,
    last_completed_date DATE
);

CREATE TABLE IF NOT EXISTS public.habit_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    reward_title VARCHAR(100) NOT NULL,
    badge_type VARCHAR(50) NOT NULL CHECK (badge_type IN ('EARLY_BIRD', 'ON_FIRE', 'CONSISTENT_MASTER')),
    badge_icon VARCHAR(50) NOT NULL,
    unlocked_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 3. EXPENSES & FINANCIAL HEALTH MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.monthly_budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    budget_month DATE NOT NULL,
    total_budget_amount NUMERIC(12, 2) NOT NULL DEFAULT 10000.00,
    currency VARCHAR(10) DEFAULT 'INR',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_monthly_budget UNIQUE (user_id, budget_month)
);

CREATE TABLE IF NOT EXISTS public.expense_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    category_name VARCHAR(50) NOT NULL,
    icon_name VARCHAR(50) DEFAULT 'category',
    color_hex VARCHAR(10) DEFAULT '#0D5CE5'
);

CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL,
    category_name VARCHAR(50) NOT NULL,
    title VARCHAR(150) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method VARCHAR(30) DEFAULT 'UPI',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 4. GOALS HIERARCHY & MILESTONES MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.goals_hierarchy (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    goal_title VARCHAR(150) NOT NULL,
    pyramid_level VARCHAR(20) NOT NULL CHECK (pyramid_level IN ('SHORT_TERM', 'MEDIUM_TERM', 'LONG_TERM')),
    target_date DATE,
    progress_percentage INT DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    goal_id UUID REFERENCES public.goals_hierarchy(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'CAREER',
    target_date DATE,
    status VARCHAR(20) DEFAULT 'NOT_STARTED' CHECK (status IN ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED')),
    completion_percentage INT DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 5. EISENHOWER MATRIX, PRIORITY MATRIX & TODOS MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.todos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) DEFAULT 'General',
    priority VARCHAR(50) DEFAULT 'MEDIUM', -- HIGH | MEDIUM | LOW
    due_date TIMESTAMPTZ,
    due_date_label VARCHAR(100),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.todo_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) DEFAULT 'Studies',
    due_date DATE,
    preferred_time TIME DEFAULT '08:00:00',
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.eisenhower_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    quadrant INT NOT NULL, -- 1: Urgent+Important, 2: Not Urgent+Important, 3: Urgent+Not Important, 4: Not Urgent+Not Important
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.eisenhower_matrix_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    quadrant VARCHAR(20) NOT NULL CHECK (quadrant IN ('DO_FIRST', 'SCHEDULE', 'DELEGATE', 'DONT_DO')),
    due_date DATE,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.priority_matrix_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    priority_level VARCHAR(20) NOT NULL CHECK (priority_level IN ('HIGH_PRIORITY', 'MEDIUM_PRIORITY', 'LOW_PRIORITY')),
    due_date DATE,
    preferred_time TIME,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 6. JOURNAL MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    body_content TEXT NOT NULL,
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    mood_rating VARCHAR(20) DEFAULT 'NEUTRAL' CHECK (mood_rating IN ('GREAT', 'GOOD', 'NEUTRAL', 'STRESSED', 'LOW')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 7. CAREER DASHBOARD & LEVEL-WISE ROADMAP MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.career_levels (
    level_number INT PRIMARY KEY CHECK (level_number >= 0),
    level_title VARCHAR(100) NOT NULL,
    xp_required INT NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS public.career_nodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    node_title VARCHAR(150) NOT NULL,
    level_number INT NOT NULL REFERENCES public.career_levels(level_number) ON DELETE CASCADE,
    node_order INT NOT NULL DEFAULT 1,
    description TEXT,
    skills_unlocked TEXT,
    status VARCHAR(20) DEFAULT 'LOCKED' CHECK (status IN ('LOCKED', 'AVAILABLE', 'COMPLETED')),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 8. ACADEMIC MODULE (SUBJECTS, UNITS, TOPICS & STUDY SESSIONS)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    subject_name VARCHAR(100) NOT NULL,
    subject_code VARCHAR(20),
    color_hex VARCHAR(10) DEFAULT '#0D5CE5',
    mastery_percentage INT DEFAULT 0 CHECK (mastery_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    unit_title VARCHAR(150) NOT NULL,
    unit_order INT DEFAULT 1,
    description TEXT,
    mastery_percentage INT DEFAULT 0 CHECK (mastery_percentage BETWEEN 0 AND 100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    topic_title VARCHAR(150) NOT NULL,
    topic_order INT DEFAULT 1,
    resource_url TEXT,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
    focus_xp_earned INT DEFAULT 0,
    session_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 9. TIME TABLE & CALENDAR SCHEDULE MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.time_table_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Monday, 7=Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    activity_title VARCHAR(150) NOT NULL,
    activity_type VARCHAR(20) DEFAULT 'STUDY' CHECK (activity_type IN ('STUDY', 'WORK', 'BREAK', 'REVISION')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL DEFAULT CURRENT_DATE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    location VARCHAR(255) DEFAULT 'Workspace',
    event_type VARCHAR(30) DEFAULT 'FOCUS_SESSION' CHECK (event_type IN ('FOCUS_SESSION', 'MEETING', 'TASK', 'STUDY')),
    reminder BOOLEAN DEFAULT TRUE,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 10. ANALYTICS & PERFORMANCE TRACKING MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.user_daily_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    record_date DATE NOT NULL DEFAULT CURRENT_DATE,
    tasks_completed_count INT DEFAULT 0,
    habits_completed_count INT DEFAULT 0,
    study_duration_minutes INT DEFAULT 0,
    total_expense_amount NUMERIC(12, 2) DEFAULT 0.00,
    daily_focus_score INT DEFAULT 0,
    CONSTRAINT unique_user_daily_analytic UNIQUE (user_id, record_date)
);

-- =============================================================================
-- 11. PAYMENTS & GOOGLE PLAY SUBSCRIPTIONS MODULE (Google Play Billing ONLY)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.plans (
    id VARCHAR(50) PRIMARY KEY, -- FREE | PREMIUM
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.plans (id, name, description)
VALUES 
    ('FREE', 'Free Tier Plan', 'Default tier with core productivity tools and max 2 habits/subjects'),
    ('PREMIUM', 'WrindhaOS Premium', 'Full access, unlimited usage, and ad-free experience')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.features (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

INSERT INTO public.features (id, name, description)
VALUES 
    ('EISENHOWER_MATRIX', 'Eisenhower Priority Table', '2x2 urgent-important priority matrix'),
    ('CALENDAR', 'Calendar Events', 'Event scheduling and timetable'),
    ('TODO', 'To-Do List', 'Task creation and sorting'),
    ('HABITS', 'Habit Tracker', 'Habit streak and tracking'),
    ('SUBJECTS', 'Subject Planner', 'Academic curriculum and topic breakdown'),
    ('GOALS', 'Goal Hierarchy Pyramid', 'Pyramid goals visualization'),
    ('CAREER_TRAJECTORY', 'Career Roadmap', 'Floating career roadmap and avatar'),
    ('ANALYTICS', 'Module Analytics', 'Bar, line, and pie chart analytics'),
    ('FOCUS_CENTRE', 'Focus Timer', 'Pomodoro and deep work countdown')
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.plan_features (
    plan_id VARCHAR(50) REFERENCES public.plans(id) ON DELETE CASCADE,
    feature_id VARCHAR(50) REFERENCES public.features(id) ON DELETE CASCADE,
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    usage_limit INT, -- NULL means unlimited
    PRIMARY KEY (plan_id, feature_id)
);

INSERT INTO public.plan_features (plan_id, feature_id, is_enabled, usage_limit)
VALUES 
    ('FREE', 'EISENHOWER_MATRIX', TRUE, NULL),
    ('FREE', 'CALENDAR', TRUE, NULL),
    ('FREE', 'TODO', TRUE, NULL),
    ('FREE', 'HABITS', TRUE, 2),
    ('FREE', 'SUBJECTS', TRUE, 2),
    ('FREE', 'GOALS', TRUE, 2),
    ('FREE', 'CAREER_TRAJECTORY', TRUE, NULL),
    ('FREE', 'ANALYTICS', TRUE, NULL),
    ('FREE', 'FOCUS_CENTRE', TRUE, NULL),
    ('PREMIUM', 'EISENHOWER_MATRIX', TRUE, NULL),
    ('PREMIUM', 'CALENDAR', TRUE, NULL),
    ('PREMIUM', 'TODO', TRUE, NULL),
    ('PREMIUM', 'HABITS', TRUE, NULL),
    ('PREMIUM', 'SUBJECTS', TRUE, NULL),
    ('PREMIUM', 'GOALS', TRUE, NULL),
    ('PREMIUM', 'CAREER_TRAJECTORY', TRUE, NULL),
    ('PREMIUM', 'ANALYTICS', TRUE, NULL),
    ('PREMIUM', 'FOCUS_CENTRE', TRUE, NULL)
ON CONFLICT (plan_id, feature_id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL DEFAULT 'google_play',
    package_name VARCHAR(150) NOT NULL DEFAULT 'com.wrindhaos.productivity',
    product_id VARCHAR(255) NOT NULL,
    purchase_token TEXT NOT NULL UNIQUE,
    order_id VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | CANCELLED | EXPIRED | PAUSED
    plan VARCHAR(50) NOT NULL DEFAULT 'PREMIUM',
    auto_renewing BOOLEAN NOT NULL DEFAULT TRUE,
    price VARCHAR(50),
    currency VARCHAR(10) DEFAULT 'INR',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    current_period_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    current_period_end TIMESTAMPTZ NOT NULL,
    cancelled_at TIMESTAMPTZ,
    expired_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.payment_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    google_order_id VARCHAR(100) NOT NULL UNIQUE,
    amount_micros BIGINT NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    payment_state VARCHAR(30) DEFAULT 'PAYMENT_RECEIVED',
    purchase_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 12. SUPER ADMIN & BACKOFFICE MANAGEMENT MODULE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'SUPPORT_AGENT' CHECK (role IN ('SUPER_ADMIN', 'SUPPORT_AGENT', 'FINANCE_ADMIN', 'MODERATOR')),
    permissions JSONB NOT NULL DEFAULT '["READ_ACCOUNT_METADATA", "READ_SUBSCRIPTION_METADATA", "READ_AGGREGATE_ANALYTICS", "MANAGE_SUPPORT_TICKETS", "MANAGE_USER_STATUS", "MANAGE_APP_SETTINGS", "MANAGE_ADMINS"]',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default Super Admin account with explicit operational permissions (NO Wildcard ALL)
INSERT INTO public.admin_users (email, full_name, role, permissions)
VALUES (
    'admin@wrindhaos.com',
    'WrindhaOS System Administrator',
    'SUPER_ADMIN',
    '["READ_ACCOUNT_METADATA", "READ_SUBSCRIPTION_METADATA", "READ_AGGREGATE_ANALYTICS", "MANAGE_SUPPORT_TICKETS", "MANAGE_USER_STATUS", "MANAGE_APP_SETTINGS", "MANAGE_ADMINS"]'
)
ON CONFLICT (email) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    target_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL, -- PLAN_OVERRIDE | USER_BAN | USER_UNBAN | FEATURE_FLAG_UPDATE | SYSTEM_BROADCAST
    details JSONB,
    ip_address VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_moderation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    is_banned BOOLEAN NOT NULL DEFAULT FALSE, -- Default FALSE: Never ban by default
    ban_reason TEXT,
    banned_by UUID REFERENCES public.admin_users(id),
    banned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    unbanned_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.app_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES public.admin_users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.app_settings (key, value, description)
VALUES 
    ('maintenance_mode', '{"enabled": false, "message": "WrindhaOS is undergoing scheduled maintenance."}', 'Global system maintenance toggle'),
    ('system_broadcast', '{"enabled": false, "text": "Welcome to WrindhaOS!"}', 'System-wide announcement banner'),
    ('max_free_habits', '{"limit": 2}', 'Max habits allowed for free plan'),
    ('max_free_subjects', '{"limit": 2}', 'Max subjects allowed for free plan')
ON CONFLICT (key) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.analytics_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    snapshot_date DATE UNIQUE NOT NULL DEFAULT CURRENT_DATE,
    total_users INT NOT NULL DEFAULT 0,
    free_users INT NOT NULL DEFAULT 0,
    premium_users INT NOT NULL DEFAULT 0,
    active_subscriptions INT NOT NULL DEFAULT 0,
    mrr_estimate_inr NUMERIC(12, 2) DEFAULT 0.00,
    dau_count INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 13. OPERATIONAL & COMPLIANCE TABLES
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.account_deletion_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status VARCHAR(30) DEFAULT 'REQUESTED' CHECK (status IN ('REQUESTED', 'SCHEDULED', 'PROCESSING', 'COMPLETED', 'CANCELED')),
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_number VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    subject VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) DEFAULT 'GENERAL' CHECK (category IN ('GENERAL', 'BILLING', 'TECHNICAL', 'ACCOUNT')),
    priority VARCHAR(20) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    status VARCHAR(30) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'IN_PROGRESS', 'WAITING_USER', 'RESOLVED', 'CLOSED')),
    assigned_admin_id UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.user_consents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    policy_type VARCHAR(50) NOT NULL CHECK (policy_type IN ('PRIVACY_POLICY', 'TERMS_OF_SERVICE', 'COOKIE_POLICY', 'MARKETING_OPT_IN')),
    policy_version VARCHAR(20) NOT NULL,
    accepted_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address VARCHAR(50),
    user_agent TEXT,
    CONSTRAINT unique_user_policy_consent UNIQUE (user_id, policy_type, policy_version)
);

CREATE TABLE IF NOT EXISTS public.legal_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('PRIVACY_POLICY', 'TERMS', 'REFUND_POLICY', 'COOKIE_POLICY', 'ACCEPTABLE_USE', 'SUBSCRIPTION_POLICY')),
    version VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    published_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    CONSTRAINT unique_document_version UNIQUE (document_type, version)
);

-- =============================================================================
-- 14. QUERY PERFORMANCE INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone_number);
CREATE INDEX IF NOT EXISTS idx_identities_user ON public.user_auth_identities(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_token ON public.subscriptions(purchase_token);
CREATE INDEX IF NOT EXISTS idx_todos_user ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_habits_user ON public.habits(user_id);
CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON public.habit_logs(user_id, completed_date);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON public.expenses(user_id, expense_date);
CREATE INDEX IF NOT EXISTS idx_calendar_user ON public.calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_eisenhower_user ON public.eisenhower_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_subjects_user ON public.subjects(user_id);
CREATE INDEX IF NOT EXISTS idx_units_subject ON public.units(subject_id);
CREATE INDEX IF NOT EXISTS idx_topics_unit ON public.topics(unit_id);
CREATE INDEX IF NOT EXISTS idx_admin_role ON public.admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_audit_target ON public.admin_audit_logs(target_user_id);
CREATE INDEX IF NOT EXISTS idx_moderation_user ON public.user_moderation(user_id);

-- =============================================================================
-- 15. ZERO-ADMIN-ACCESS ROW LEVEL SECURITY (RLS) POLICIES
--     NON-NEGOTIABLE RULE: auth.uid() = user_id owner isolation.
--     Zero admin read policies on private user tables.
-- =============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_referrals ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_rewards ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.monthly_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.goals_hierarchy ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.eisenhower_matrix_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eisenhower_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.priority_matrix_tasks ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.career_nodes ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.time_table_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todo_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_daily_analytics ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

-- Owner-Only RLS Policies (auth.uid() = user_id)
DROP POLICY IF EXISTS users_owner_policy ON public.users;
CREATE POLICY users_owner_policy ON public.users FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS user_profiles_owner_policy ON public.user_profiles;
CREATE POLICY user_profiles_owner_policy ON public.user_profiles FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS notification_settings_owner_policy ON public.notification_settings;
CREATE POLICY notification_settings_owner_policy ON public.notification_settings FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS habits_owner_policy ON public.habits;
CREATE POLICY habits_owner_policy ON public.habits FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_logs_owner_policy ON public.habit_logs;
CREATE POLICY habit_logs_owner_policy ON public.habit_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_streaks_owner_policy ON public.habit_streaks;
CREATE POLICY habit_streaks_owner_policy ON public.habit_streaks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_rewards_owner_policy ON public.habit_rewards;
CREATE POLICY habit_rewards_owner_policy ON public.habit_rewards FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS monthly_budgets_owner_policy ON public.monthly_budgets;
CREATE POLICY monthly_budgets_owner_policy ON public.monthly_budgets FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS expense_categories_owner_policy ON public.expense_categories;
CREATE POLICY expense_categories_owner_policy ON public.expense_categories FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS expenses_owner_policy ON public.expenses;
CREATE POLICY expenses_owner_policy ON public.expenses FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS goals_hierarchy_owner_policy ON public.goals_hierarchy;
CREATE POLICY goals_hierarchy_owner_policy ON public.goals_hierarchy FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS milestones_owner_policy ON public.milestones;
CREATE POLICY milestones_owner_policy ON public.milestones FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS eisenhower_owner_policy ON public.eisenhower_matrix_tasks;
CREATE POLICY eisenhower_owner_policy ON public.eisenhower_matrix_tasks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS eisenhower_tasks_owner_policy ON public.eisenhower_tasks;
CREATE POLICY eisenhower_tasks_owner_policy ON public.eisenhower_tasks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS priority_matrix_owner_policy ON public.priority_matrix_tasks;
CREATE POLICY priority_matrix_owner_policy ON public.priority_matrix_tasks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Journal Entries (Strictly Owner-Only, ZERO Admin Policy)
DROP POLICY IF EXISTS journal_owner_policy ON public.journal_entries;
CREATE POLICY journal_owner_policy ON public.journal_entries FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS career_nodes_owner_policy ON public.career_nodes;
CREATE POLICY career_nodes_owner_policy ON public.career_nodes FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS subjects_owner_policy ON public.subjects;
CREATE POLICY subjects_owner_policy ON public.subjects FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS units_owner_policy ON public.units;
CREATE POLICY units_owner_policy ON public.units FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS topics_owner_policy ON public.topics;
CREATE POLICY topics_owner_policy ON public.topics FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS study_sessions_owner_policy ON public.study_sessions;
CREATE POLICY study_sessions_owner_policy ON public.study_sessions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS time_table_owner_policy ON public.time_table_slots;
CREATE POLICY time_table_owner_policy ON public.time_table_slots FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS calendar_events_owner_policy ON public.calendar_events;
CREATE POLICY calendar_events_owner_policy ON public.calendar_events FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS todos_owner_policy ON public.todos;
CREATE POLICY todos_owner_policy ON public.todos FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS todo_tasks_owner_policy ON public.todo_tasks;
CREATE POLICY todo_tasks_owner_policy ON public.todo_tasks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS user_analytics_owner_policy ON public.user_daily_analytics;
CREATE POLICY user_analytics_owner_policy ON public.user_daily_analytics FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS deletion_requests_owner_policy ON public.account_deletion_requests;
CREATE POLICY deletion_requests_owner_policy ON public.account_deletion_requests FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS user_consents_owner_policy ON public.user_consents;
CREATE POLICY user_consents_owner_policy ON public.user_consents FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS support_tickets_user_policy ON public.support_tickets;
CREATE POLICY support_tickets_user_policy ON public.support_tickets FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS legal_documents_public_policy ON public.legal_documents;
CREATE POLICY legal_documents_public_policy ON public.legal_documents FOR SELECT USING (is_active = true);

-- =============================================================================
-- 16. DEVELOPER & DBA AES-256 CIPHERTEXT ENCRYPTION HELPERS
-- =============================================================================

CREATE OR REPLACE FUNCTION encrypt_journal_content(secret_key TEXT, plain_text TEXT)
RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(plain_text, secret_key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION decrypt_journal_content(secret_key TEXT, cipher_data BYTEA)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(cipher_data, secret_key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
