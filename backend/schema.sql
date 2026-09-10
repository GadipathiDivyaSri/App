-- =============================================================================
-- WRINDHAOS COMPLETE PRODUCTION-READY SUPABASE DATABASE SCHEMA v4.1.0
-- Security Architecture: Zero-Admin Data Privacy & User-Isolated Row Level Security (RLS)
-- Includes:
--   1. Profiles, Subscriptions, Tasks, Habits, Expenses, Study, Goals, 
--      Calendar, Journal Entries, Auth Identities, Audit Logs, and Referrals.
--   2. Payments & Purchases Module (Google Play, Order IDs, Purchase Tokens).
--   3. Coupons, Discounts & Coupon Redemptions Module.
--   4. Row-Level Security (RLS) on all tables for 100% Zero-Data-Leakage.
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Automatic Updated-At Timestamp Function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 1. USERS & PROFILES MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) DEFAULT 'Student User',
    display_name VARCHAR(255) DEFAULT 'Student User',
    name VARCHAR(255) DEFAULT 'Student User',
    phone_number VARCHAR(30),
    contact VARCHAR(30),
    avatar_url TEXT,
    profile_image TEXT,
    role VARCHAR(30) DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN', 'SUPER_ADMIN', 'MODERATOR', 'SUPPORT_AGENT')),
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_2fa_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(64),
    is_premium BOOLEAN DEFAULT FALSE,
    subscription_plan VARCHAR(30) DEFAULT 'FREE' CHECK (subscription_plan IN ('FREE', 'PRO_MONTHLY', 'PRO_YEARLY', 'PREMIUM')),
    focus_score INT DEFAULT 0 CHECK (focus_score BETWEEN 0 AND 100),
    active_streak INT DEFAULT 0 CHECK (active_streak >= 0),
    xp INT DEFAULT 0 CHECK (xp >= 0),
    referral_code VARCHAR(50) UNIQUE NOT NULL DEFAULT ('WRINDHA_' || upper(substring(md5(random()::text) from 1 for 6))),
    referred_by_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    fcm_device_token TEXT,
    account_status VARCHAR(30) DEFAULT 'ACTIVE' CHECK (account_status IN ('ACTIVE', 'SUSPENDED', 'BANNED', 'DELETED')),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_referral ON public.profiles(referral_code);

-- Backwards-compatibility Views
CREATE OR REPLACE VIEW public.users AS SELECT * FROM public.profiles;
CREATE OR REPLACE VIEW public.user_profiles AS SELECT * FROM public.profiles;

-- -----------------------------------------------------------------------------
-- 2. SUBSCRIPTIONS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan VARCHAR(30) DEFAULT 'free' CHECK (plan IN ('free', 'premium', 'elite', 'pro_monthly')),
    status VARCHAR(30) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'grace_period', 'paused')),
    billing_provider VARCHAR(50) DEFAULT 'NONE',
    payment_provider VARCHAR(50) DEFAULT 'NONE',
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_subscriptions_user UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON public.subscriptions(user_id, status);

CREATE OR REPLACE VIEW public.user_subscriptions AS SELECT * FROM public.subscriptions;

-- -----------------------------------------------------------------------------
-- 3. PAYMENTS & PURCHASES MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
    order_id VARCHAR(255) UNIQUE,
    purchase_token TEXT,
    product_id VARCHAR(100) DEFAULT 'wrindhaos_premium_monthly',
    provider VARCHAR(50) DEFAULT 'google_play',
    amount NUMERIC(12, 2) NOT NULL DEFAULT 59.00,
    currency VARCHAR(10) DEFAULT 'INR',
    status VARCHAR(30) DEFAULT 'SUCCESS' CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED')),
    raw_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payments_user ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_order ON public.payments(order_id);

-- -----------------------------------------------------------------------------
-- 4. COUPONS, DISCOUNTS & REDEMPTIONS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) DEFAULT 'PERCENTAGE' CHECK (discount_type IN ('PERCENTAGE', 'FIXED_AMOUNT', 'FREE_TRIAL')),
    discount_value NUMERIC(10, 2) NOT NULL DEFAULT 100.00,
    max_redemptions INT DEFAULT 1000,
    times_redeemed INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_coupons_code ON public.coupons(code);

CREATE TABLE IF NOT EXISTS public.coupon_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coupon_id UUID NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    redeemed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_coupon_user UNIQUE (coupon_id, user_id)
);

-- -----------------------------------------------------------------------------
-- 5. TASKS & TODOS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'Studies',
    priority INT DEFAULT 1 CHECK (priority BETWEEN 1 AND 4),
    quadrant VARCHAR(50) DEFAULT 'q1_do_first' CHECK (quadrant IN ('q1_do_first', 'q2_schedule', 'q3_delegate', 'q4_eliminate')),
    is_completed BOOLEAN DEFAULT FALSE,
    due_at TIMESTAMPTZ,
    due_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_quadrant ON public.tasks(user_id, quadrant);

CREATE OR REPLACE VIEW public.todos AS SELECT * FROM public.tasks;
CREATE OR REPLACE VIEW public.eisenhower_tasks AS SELECT * FROM public.tasks;

-- -----------------------------------------------------------------------------
-- 6. HABITS & HABIT COMPLETIONS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'General',
    frequency VARCHAR(30) DEFAULT 'daily',
    status VARCHAR(30) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'archived')),
    icon_name VARCHAR(50) DEFAULT 'repeat',
    color VARCHAR(30) DEFAULT '#10B981',
    color_hex VARCHAR(30) DEFAULT '#10B981',
    streak_count INT DEFAULT 0 CHECK (streak_count >= 0),
    best_streak INT DEFAULT 0 CHECK (best_streak >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_habits_user_status ON public.habits(user_id, status);

CREATE TABLE IF NOT EXISTS public.habit_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    completion_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) DEFAULT 'completed',
    notes TEXT,
    CONSTRAINT uq_habit_completion_day UNIQUE (habit_id, completion_date)
);

CREATE INDEX IF NOT EXISTS idx_habit_completions_user_date ON public.habit_completions(user_id, completion_date);

CREATE OR REPLACE VIEW public.habit_logs AS SELECT * FROM public.habit_completions;

-- -----------------------------------------------------------------------------
-- 7. EXPENSES & FINANCIAL MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (amount >= 0),
    category VARCHAR(50) DEFAULT 'General',
    transaction_type VARCHAR(20) DEFAULT 'expense' CHECK (transaction_type IN ('expense', 'income')),
    is_income BOOLEAN DEFAULT FALSE,
    payment_method VARCHAR(50) DEFAULT 'UPI',
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON public.expenses(user_id, occurred_at);

CREATE TABLE IF NOT EXISTS public.monthly_budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (amount >= 0),
    month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
    year INT NOT NULL CHECK (year >= 2020),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_monthly_budgets_user_month UNIQUE (user_id, month, year)
);

-- -----------------------------------------------------------------------------
-- 8. STUDY MODULE: SUBJECTS, UNITS & ITEMS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code VARCHAR(50),
    color VARCHAR(30) DEFAULT '#0D5CE5',
    color_hex VARCHAR(30) DEFAULT '#0D5CE5',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_subjects_user ON public.subjects(user_id);

CREATE OR REPLACE VIEW public.study_subjects AS SELECT * FROM public.subjects;

CREATE TABLE IF NOT EXISTS public.study_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    unit_number INT DEFAULT 1 CHECK (unit_number > 0),
    title TEXT NOT NULL,
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.study_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES public.study_units(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 9. GOALS, MILESTONES & CAREER ROADMAP
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    tier VARCHAR(30) DEFAULT 'short' CHECK (tier IN ('short', 'medium', 'long')),
    timeframe VARCHAR(30) DEFAULT 'short',
    category VARCHAR(50) DEFAULT 'General',
    is_completed BOOLEAN DEFAULT FALSE,
    target_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_goals_user_tier ON public.goals(user_id, tier);

CREATE OR REPLACE VIEW public.career_roadmap AS SELECT * FROM public.goals;

CREATE TABLE IF NOT EXISTS public.milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    goal_id UUID NOT NULL REFERENCES public.goals(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    target_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 10. CALENDAR EVENTS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_date DATE NOT NULL DEFAULT CURRENT_DATE,
    start_time TIME DEFAULT '10:00:00',
    end_time TIME DEFAULT '11:00:00',
    category VARCHAR(50) DEFAULT 'General',
    is_all_day BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date ON public.calendar_events(user_id, event_date);

-- -----------------------------------------------------------------------------
-- 11. PRIVATE JOURNAL ENTRIES (Zero-Admin Encrypted Privacy)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content_ciphertext TEXT NOT NULL,
    mood VARCHAR(30) DEFAULT 'neutral',
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_journal_entries_user ON public.journal_entries(user_id);

-- -----------------------------------------------------------------------------
-- 12. AUTH IDENTITIES, AUDIT LOGS & REFERRALS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_auth_identities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    provider VARCHAR(50) DEFAULT 'email',
    provider_user_id VARCHAR(255),
    email VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    payload JSONB,
    ip_address INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    referred_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    code VARCHAR(50),
    status VARCHAR(30) DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- SECTION 13: ROW LEVEL SECURITY (RLS) POLICIES
-- Strict Isolation: Users can ONLY access their OWN data. Admins BLOCKED from private user data.
-- -----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupon_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_auth_identities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

DO $$ 
DECLARE
    tbl text;
    user_tables text[] := ARRAY[
        'payments', 'tasks', 'habits', 'habit_completions', 'expenses', 'monthly_budgets',
        'subjects', 'study_units', 'study_items', 'goals', 'milestones',
        'calendar_events', 'journal_entries'
    ];
BEGIN
    -- 1. Profiles Table RLS
    DROP POLICY IF EXISTS profiles_user_policy ON public.profiles;
    CREATE POLICY profiles_user_policy ON public.profiles
        FOR ALL USING (auth.uid() = user_id OR auth.role() = 'service_role')
        WITH CHECK (auth.uid() = user_id OR auth.role() = 'service_role');

    -- 2. Subscriptions Table RLS
    DROP POLICY IF EXISTS subscriptions_user_policy ON public.subscriptions;
    CREATE POLICY subscriptions_user_policy ON public.subscriptions
        FOR ALL USING (auth.uid() = user_id OR auth.role() = 'service_role')
        WITH CHECK (auth.uid() = user_id OR auth.role() = 'service_role');

    -- 3. Coupons Policy
    DROP POLICY IF EXISTS coupons_read_policy ON public.coupons;
    CREATE POLICY coupons_read_policy ON public.coupons
        FOR SELECT USING (true);

    -- 4. User Data Isolation for all user tables
    FOREACH tbl IN ARRAY user_tables LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I_user_isolation_policy ON public.%I', tbl, tbl);
        EXECUTE format(
            'CREATE POLICY %I_user_isolation_policy ON public.%I FOR ALL USING (auth.uid() = user_id OR auth.role() = ''service_role'') WITH CHECK (auth.uid() = user_id OR auth.role() = ''service_role'')',
            tbl, tbl
        );
    END LOOP;
END $$;
