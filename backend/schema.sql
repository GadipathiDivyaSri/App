-- =============================================================================
-- WRINDHAOS COMPLETE PRODUCTION-READY SUPABASE DATABASE SCHEMA v5.0.0
-- Security Architecture: Zero-Admin Data Privacy & User-Isolated Row Level Security (RLS)
-- Idempotent schema definition & migration script for existing & new Supabase projects.
-- =============================================================================

-- Enable required extensions
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
    role VARCHAR(30) DEFAULT 'USER',
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_2fa_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(64),
    is_premium BOOLEAN DEFAULT FALSE,
    subscription_plan VARCHAR(30) DEFAULT 'FREE',
    focus_score INT DEFAULT 0,
    active_streak INT DEFAULT 0,
    xp INT DEFAULT 0,
    referral_code VARCHAR(50) UNIQUE NOT NULL DEFAULT ('WRINDHA_' || upper(substring(md5(gen_random_uuid()::text) from 1 for 6))),
    referred_by_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    fcm_device_token TEXT,
    account_status VARCHAR(30) DEFAULT 'ACTIVE',
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Ensure all columns exist on existing profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name VARCHAR(255) DEFAULT 'Student User';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS display_name VARCHAR(255) DEFAULT 'Student User';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS name VARCHAR(255) DEFAULT 'Student User';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_number VARCHAR(30);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS contact VARCHAR(30);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS profile_image TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role VARCHAR(30) DEFAULT 'USER';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_2fa_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS two_factor_secret VARCHAR(64);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS subscription_plan VARCHAR(30) DEFAULT 'FREE';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS focus_score INT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS active_streak INT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS xp INT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referral_code VARCHAR(50);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_device_token TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS account_status VARCHAR(30) DEFAULT 'ACTIVE';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_referral ON public.profiles(referral_code);

-- Deterministic Referral Code Generation Trigger with Collision Retry Loop
CREATE OR REPLACE FUNCTION public.set_referral_code()
RETURNS TRIGGER AS $$
DECLARE
    new_code TEXT;
    done BOOLEAN := FALSE;
BEGIN
    IF NEW.referral_code IS NULL OR NEW.referral_code = '' OR NEW.referral_code LIKE 'WRINDHA_%' THEN
        WHILE NOT done LOOP
            new_code := 'WRINDHA_' || upper(substring(md5(gen_random_uuid()::text) from 1 for 6));
            IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE referral_code = new_code) THEN
                NEW.referral_code := new_code;
                done := TRUE;
            END IF;
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_referral_code ON public.profiles;
CREATE TRIGGER trg_set_referral_code
    BEFORE INSERT ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_referral_code();

-- Privilege Escalation Protection: Block users from mutating 'role' via UPDATE
CREATE OR REPLACE FUNCTION public.prevent_role_escalation()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.role IS DISTINCT FROM NEW.role AND (auth.jwt() ->> 'role') IS DISTINCT FROM 'service_role' THEN
        NEW.role := OLD.role;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_role_escalation ON public.profiles;
CREATE TRIGGER trg_prevent_role_escalation
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.prevent_role_escalation();

-- Auto-Bootstrap Profile Trigger for New Auth Users (Solves Chicken-and-Egg RLS)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER SECURITY DEFINER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, email, username, full_name, display_name, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', REPLACE(SPLIT_PART(NEW.email, '@', 1), '.', '_')),
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Student User'),
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Student User'),
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Student User')
    )
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backwards-compatibility Views with Explicit Column Lists
DROP VIEW IF EXISTS public.users CASCADE;
CREATE VIEW public.users AS 
SELECT id, user_id, username, email, full_name, display_name, name, phone_number, contact, avatar_url, profile_image, role, is_email_verified, is_2fa_enabled, is_premium, subscription_plan, focus_score, active_streak, xp, referral_code, created_at, updated_at, last_login_at
FROM public.profiles;

DROP VIEW IF EXISTS public.user_profiles CASCADE;
CREATE VIEW public.user_profiles AS 
SELECT id, user_id, username, email, full_name, display_name, name, phone_number, contact, avatar_url, profile_image, role, is_email_verified, is_2fa_enabled, is_premium, subscription_plan, focus_score, active_streak, xp, referral_code, created_at, updated_at, last_login_at
FROM public.profiles;

-- -----------------------------------------------------------------------------
-- 2. SUBSCRIPTIONS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan VARCHAR(30) DEFAULT 'free',
    status VARCHAR(30) DEFAULT 'active',
    billing_provider VARCHAR(50) DEFAULT 'NONE',
    payment_provider VARCHAR(50) DEFAULT 'NONE',
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS plan VARCHAR(30) DEFAULT 'free';
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'active';
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS billing_provider VARCHAR(50) DEFAULT 'NONE';
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS payment_provider VARCHAR(50) DEFAULT 'NONE';
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;
ALTER TABLE public.subscriptions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON public.subscriptions(user_id, status);

DROP VIEW IF EXISTS public.user_subscriptions CASCADE;
CREATE VIEW public.user_subscriptions AS 
SELECT id, user_id, plan, status, billing_provider, payment_provider, started_at, expires_at, created_at, updated_at
FROM public.subscriptions;

-- -----------------------------------------------------------------------------
-- 3. PAYMENTS & PURCHASES MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
    order_id VARCHAR(255) UNIQUE,
    google_order_id VARCHAR(255),
    purchase_token TEXT,
    product_id VARCHAR(100) DEFAULT 'wrindhaos_premium_monthly',
    provider VARCHAR(50) DEFAULT 'google_play',
    amount NUMERIC(12, 2) NOT NULL DEFAULT 59.00,
    currency VARCHAR(10) DEFAULT 'INR',
    status VARCHAR(30) DEFAULT 'SUCCESS',
    raw_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS order_id VARCHAR(255);
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS google_order_id VARCHAR(255);
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS purchase_token TEXT;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS product_id VARCHAR(100) DEFAULT 'wrindhaos_premium_monthly';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS provider VARCHAR(50) DEFAULT 'google_play';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS amount NUMERIC(12, 2) DEFAULT 59.00;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS currency VARCHAR(10) DEFAULT 'INR';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'SUCCESS';
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS raw_payload JSONB;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_payments_user ON public.payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_order ON public.payments(order_id);

-- -----------------------------------------------------------------------------
-- 4. COUPONS, DISCOUNTS & REDEMPTIONS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_type VARCHAR(30) DEFAULT 'PERCENTAGE',
    discount_value NUMERIC(10, 2) NOT NULL DEFAULT 100.00,
    max_redemptions INT DEFAULT 1000,
    times_redeemed INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS discount_type VARCHAR(30) DEFAULT 'PERCENTAGE';
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS discount_value NUMERIC(10, 2) DEFAULT 100.00;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS max_redemptions INT DEFAULT 1000;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS times_redeemed INT DEFAULT 0;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_coupons_code ON public.coupons(code);

CREATE TABLE IF NOT EXISTS public.coupon_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coupon_id UUID NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    redeemed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_coupon_user UNIQUE (coupon_id, user_id)
);

ALTER TABLE public.coupon_redemptions ADD COLUMN IF NOT EXISTS redeemed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Secure Coupon Redemption RPC Function (Protects Leaking Coupon List)
CREATE OR REPLACE FUNCTION public.redeem_coupon(p_code TEXT)
RETURNS JSONB SECURITY DEFINER AS $$
DECLARE
    v_coupon public.coupons%ROWTYPE;
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Authentication required.');
    END IF;

    SELECT * INTO v_coupon FROM public.coupons 
    WHERE upper(code) = upper(p_code) AND is_active = TRUE
    AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP);

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Invalid or expired coupon code.');
    END IF;

    IF v_coupon.times_redeemed >= v_coupon.max_redemptions THEN
        RETURN jsonb_build_object('success', false, 'message', 'Coupon redemption limit reached.');
    END IF;

    IF EXISTS (SELECT 1 FROM public.coupon_redemptions WHERE coupon_id = v_coupon.id AND user_id = v_user_id) THEN
        RETURN jsonb_build_object('success', false, 'message', 'You have already redeemed this coupon.');
    END IF;

    INSERT INTO public.coupon_redemptions (coupon_id, user_id) VALUES (v_coupon.id, v_user_id);
    UPDATE public.coupons SET times_redeemed = times_redeemed + 1 WHERE id = v_coupon.id;

    RETURN jsonb_build_object('success', true, 'message', 'Coupon redeemed successfully!', 'discount_type', v_coupon.discount_type, 'discount_value', v_coupon.discount_value);
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 5. TASKS & TODOS MODULE (Eisenhower Matrix Support)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'Studies',
    priority INT DEFAULT 1,
    quadrant VARCHAR(50) DEFAULT 'q1_do_first',
    is_completed BOOLEAN DEFAULT FALSE,
    due_at TIMESTAMPTZ,
    due_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'Studies';
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS priority INT DEFAULT 1;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS quadrant VARCHAR(50) DEFAULT 'q1_do_first';
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS due_at TIMESTAMPTZ;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS due_date DATE;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_tasks_user_quadrant ON public.tasks(user_id, quadrant);

DROP VIEW IF EXISTS public.todos CASCADE;
CREATE VIEW public.todos AS 
SELECT id, user_id, title, description, category, priority, quadrant, is_completed, due_at, due_date, created_at, updated_at
FROM public.tasks;

DROP VIEW IF EXISTS public.eisenhower_tasks CASCADE;
CREATE VIEW public.eisenhower_tasks AS 
SELECT id, user_id, title, description, category, priority, quadrant, is_completed, due_at, due_date, created_at, updated_at
FROM public.tasks;

-- -----------------------------------------------------------------------------
-- 6. HABITS & HABIT COMPLETIONS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'General',
    frequency VARCHAR(50) DEFAULT 'daily',
    status VARCHAR(30) DEFAULT 'active',
    icon_name VARCHAR(50) DEFAULT 'repeat',
    color VARCHAR(30) DEFAULT '#10B981',
    color_hex VARCHAR(30) DEFAULT '#10B981',
    streak_count INT DEFAULT 0,
    streak_day INT DEFAULT 0,
    best_streak INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'General';
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS frequency VARCHAR(50) DEFAULT 'daily';
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'active';
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS icon_name VARCHAR(50) DEFAULT 'repeat';
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS color VARCHAR(30) DEFAULT '#10B981';
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS color_hex VARCHAR(30) DEFAULT '#10B981';
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS streak_count INT DEFAULT 0;
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS streak_day INT DEFAULT 0;
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS best_streak INT DEFAULT 0;
ALTER TABLE public.habits ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_habits_user_status ON public.habits(user_id, status);

CREATE TABLE IF NOT EXISTS public.habit_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    completion_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completed_date DATE DEFAULT CURRENT_DATE,
    date DATE DEFAULT CURRENT_DATE,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) DEFAULT 'completed',
    notes TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.habit_completions ADD COLUMN IF NOT EXISTS completion_date DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE public.habit_completions ADD COLUMN IF NOT EXISTS completed_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.habit_completions ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.habit_completions ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE public.habit_completions ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'completed';
ALTER TABLE public.habit_completions ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.habit_completions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_habit_completion_day'
    ) THEN
        ALTER TABLE public.habit_completions ADD CONSTRAINT uq_habit_completion_day UNIQUE (habit_id, completion_date);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_habit_completions_user_date ON public.habit_completions(user_id, completion_date);

DROP VIEW IF EXISTS public.habit_logs CASCADE;
CREATE VIEW public.habit_logs AS 
SELECT id, user_id, habit_id, completion_date, completed_date, date, completed_at, status, notes, updated_at
FROM public.habit_completions;

-- -----------------------------------------------------------------------------
-- 7. EXPENSES & FINANCIAL MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    category VARCHAR(50) DEFAULT 'General',
    transaction_type VARCHAR(30) DEFAULT 'expense',
    is_income BOOLEAN DEFAULT FALSE,
    payment_method VARCHAR(50) DEFAULT 'UPI',
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expense_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS amount NUMERIC(12, 2) DEFAULT 0.00;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'General';
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS transaction_type VARCHAR(30) DEFAULT 'expense';
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS is_income BOOLEAN DEFAULT FALSE;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'UPI';
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS occurred_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS expense_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON public.expenses(user_id, occurred_at);

CREATE TABLE IF NOT EXISTS public.monthly_budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    month INT NOT NULL,
    year INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.monthly_budgets ADD COLUMN IF NOT EXISTS amount NUMERIC(12, 2) DEFAULT 0.00;
ALTER TABLE public.monthly_budgets ADD COLUMN IF NOT EXISTS month INT;
ALTER TABLE public.monthly_budgets ADD COLUMN IF NOT EXISTS year INT;
ALTER TABLE public.monthly_budgets ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_monthly_budgets_user_month'
    ) THEN
        ALTER TABLE public.monthly_budgets ADD CONSTRAINT uq_monthly_budgets_user_month UNIQUE (user_id, month, year);
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 8. STUDY MODULE: SUBJECTS, UNITS & ITEMS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    subject_name TEXT,
    code VARCHAR(50),
    color VARCHAR(30) DEFAULT '#0D5CE5',
    color_hex VARCHAR(30) DEFAULT '#0D5CE5',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.subjects ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.subjects ADD COLUMN IF NOT EXISTS subject_name TEXT;
ALTER TABLE public.subjects ADD COLUMN IF NOT EXISTS code VARCHAR(50);
ALTER TABLE public.subjects ADD COLUMN IF NOT EXISTS color VARCHAR(30) DEFAULT '#0D5CE5';
ALTER TABLE public.subjects ADD COLUMN IF NOT EXISTS color_hex VARCHAR(30) DEFAULT '#0D5CE5';
ALTER TABLE public.subjects ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_subjects_user ON public.subjects(user_id);

DROP VIEW IF EXISTS public.study_subjects CASCADE;
CREATE VIEW public.study_subjects AS 
SELECT id, user_id, name, subject_name, code, color, color_hex, created_at, updated_at
FROM public.subjects;

CREATE TABLE IF NOT EXISTS public.study_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    unit_number INT DEFAULT 1,
    order_num INT DEFAULT 1,
    title TEXT NOT NULL,
    unit_title TEXT,
    status VARCHAR(30) DEFAULT 'pending',
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.study_units ADD COLUMN IF NOT EXISTS unit_number INT DEFAULT 1;
ALTER TABLE public.study_units ADD COLUMN IF NOT EXISTS order_num INT DEFAULT 1;
ALTER TABLE public.study_units ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.study_units ADD COLUMN IF NOT EXISTS unit_title TEXT;
ALTER TABLE public.study_units ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'pending';
ALTER TABLE public.study_units ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE public.study_units ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_study_units_order ON public.study_units(subject_id, unit_number);

CREATE TABLE IF NOT EXISTS public.study_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES public.study_units(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    order_num INT DEFAULT 1,
    type VARCHAR(30) DEFAULT 'TASK',
    status VARCHAR(30) DEFAULT 'pending',
    is_completed BOOLEAN DEFAULT FALSE,
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.study_items ADD COLUMN IF NOT EXISTS type VARCHAR(30) DEFAULT 'TASK';
ALTER TABLE public.study_items ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'pending';
ALTER TABLE public.study_items ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE public.study_items ADD COLUMN IF NOT EXISTS due_date TIMESTAMPTZ;
ALTER TABLE public.study_items ADD COLUMN IF NOT EXISTS order_num INT DEFAULT 1;
ALTER TABLE public.study_items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- -----------------------------------------------------------------------------
-- 9. GOALS, MILESTONES & CAREER ROADMAP
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    tier VARCHAR(30) DEFAULT 'short',
    timeframe VARCHAR(30) DEFAULT 'short',
    section VARCHAR(50) DEFAULT 'GOAL',
    category VARCHAR(50) DEFAULT 'General',
    is_completed BOOLEAN DEFAULT FALSE,
    target_date DATE,
    aligned_purpose TEXT,
    progress_percentage NUMERIC(5, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS tier VARCHAR(30) DEFAULT 'short';
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS timeframe VARCHAR(30) DEFAULT 'short';
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS section VARCHAR(50) DEFAULT 'GOAL';
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'General';
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS target_date DATE;
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS aligned_purpose TEXT;
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS progress_percentage NUMERIC(5, 2) DEFAULT 0.00;
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_goals_user_tier ON public.goals(user_id, tier);

DROP VIEW IF EXISTS public.career_roadmap CASCADE;
CREATE VIEW public.career_roadmap AS 
SELECT id, user_id, title, description, tier, timeframe, section, category, is_completed, target_date, aligned_purpose, progress_percentage, created_at, updated_at
FROM public.goals;

CREATE TABLE IF NOT EXISTS public.milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    goal_id UUID NOT NULL REFERENCES public.goals(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    milestone_title TEXT,
    description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    target_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS milestone_title TEXT;
ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;
ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS target_date DATE;
ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- -----------------------------------------------------------------------------
-- 10. CALENDAR EVENTS MODULE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_date DATE NOT NULL DEFAULT CURRENT_DATE,
    date DATE DEFAULT CURRENT_DATE,
    start_time TIME DEFAULT '10:00:00',
    end_time TIME DEFAULT '11:00:00',
    category VARCHAR(50) DEFAULT 'General',
    event_type VARCHAR(50) DEFAULT 'General',
    location VARCHAR(255) DEFAULT 'Workspace A',
    is_all_day BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS event_date DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS start_time TIME DEFAULT '10:00:00';
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS end_time TIME DEFAULT '11:00:00';
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'General';
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS event_type VARCHAR(50) DEFAULT 'General';
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS location VARCHAR(255) DEFAULT 'Workspace A';
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS is_all_day BOOLEAN DEFAULT FALSE;
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date ON public.calendar_events(user_id, event_date);

-- -----------------------------------------------------------------------------
-- 11. PRIVATE JOURNAL ENTRIES (Zero-Admin Encrypted Privacy)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content_ciphertext TEXT DEFAULT '',
    content TEXT DEFAULT '',
    encryption_version VARCHAR(30) DEFAULT 'AES-GCM-256',
    key_id VARCHAR(100) DEFAULT 'v1_master',
    mood VARCHAR(30) DEFAULT 'neutral',
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS content_ciphertext TEXT DEFAULT '';
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS content TEXT DEFAULT '';
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS encryption_version VARCHAR(30) DEFAULT 'AES-GCM-256';
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS key_id VARCHAR(100) DEFAULT 'v1_master';
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS mood VARCHAR(30) DEFAULT 'neutral';
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS entry_date DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

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
-- AUTOMATIC UPDATED_AT TRIGGER ATTACHMENTS
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER trg_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_payments_updated_at ON public.payments;
CREATE TRIGGER trg_payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_coupons_updated_at ON public.coupons;
CREATE TRIGGER trg_coupons_updated_at BEFORE UPDATE ON public.coupons FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_tasks_updated_at ON public.tasks;
CREATE TRIGGER trg_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_habits_updated_at ON public.habits;
CREATE TRIGGER trg_habits_updated_at BEFORE UPDATE ON public.habits FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_habit_completions_updated_at ON public.habit_completions;
CREATE TRIGGER trg_habit_completions_updated_at BEFORE UPDATE ON public.habit_completions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_expenses_updated_at ON public.expenses;
CREATE TRIGGER trg_expenses_updated_at BEFORE UPDATE ON public.expenses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_monthly_budgets_updated_at ON public.monthly_budgets;
CREATE TRIGGER trg_monthly_budgets_updated_at BEFORE UPDATE ON public.monthly_budgets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_subjects_updated_at ON public.subjects;
CREATE TRIGGER trg_subjects_updated_at BEFORE UPDATE ON public.subjects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_study_units_updated_at ON public.study_units;
CREATE TRIGGER trg_study_units_updated_at BEFORE UPDATE ON public.study_units FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_study_items_updated_at ON public.study_items;
CREATE TRIGGER trg_study_items_updated_at BEFORE UPDATE ON public.study_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_goals_updated_at ON public.goals;
CREATE TRIGGER trg_goals_updated_at BEFORE UPDATE ON public.goals FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_milestones_updated_at ON public.milestones;
CREATE TRIGGER trg_milestones_updated_at BEFORE UPDATE ON public.milestones FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_calendar_events_updated_at ON public.calendar_events;
CREATE TRIGGER trg_calendar_events_updated_at BEFORE UPDATE ON public.calendar_events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_journal_entries_updated_at ON public.journal_entries;
CREATE TRIGGER trg_journal_entries_updated_at BEFORE UPDATE ON public.journal_entries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

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

-- 1. Profiles Table Policies (Solves Chicken-and-Egg Profile Insertion)
DROP POLICY IF EXISTS profiles_select_policy ON public.profiles;
CREATE POLICY profiles_select_policy ON public.profiles
    FOR SELECT USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS profiles_insert_policy ON public.profiles;
CREATE POLICY profiles_insert_policy ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS profiles_update_policy ON public.profiles;
CREATE POLICY profiles_update_policy ON public.profiles
    FOR UPDATE USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role')
    WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS profiles_delete_policy ON public.profiles;
CREATE POLICY profiles_delete_policy ON public.profiles
    FOR DELETE USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

-- 2. Subscriptions Table Policies
DROP POLICY IF EXISTS subscriptions_user_policy ON public.subscriptions;
CREATE POLICY subscriptions_user_policy ON public.subscriptions
    FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role')
    WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

-- 3. Coupons Read Policy (Restricted to Active Non-Expired Coupons)
DROP POLICY IF EXISTS coupons_read_policy ON public.coupons;
CREATE POLICY coupons_read_policy ON public.coupons
    FOR SELECT USING (is_active = TRUE AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP));

-- 4. User Isolation Policies for all user data tables (Explicit CREATE POLICY statements)
DROP POLICY IF EXISTS payments_user_isolation_policy ON public.payments;
CREATE POLICY payments_user_isolation_policy ON public.payments FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS tasks_user_isolation_policy ON public.tasks;
CREATE POLICY tasks_user_isolation_policy ON public.tasks FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS habits_user_isolation_policy ON public.habits;
CREATE POLICY habits_user_isolation_policy ON public.habits FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS habit_completions_user_isolation_policy ON public.habit_completions;
CREATE POLICY habit_completions_user_isolation_policy ON public.habit_completions FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS expenses_user_isolation_policy ON public.expenses;
CREATE POLICY expenses_user_isolation_policy ON public.expenses FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS monthly_budgets_user_isolation_policy ON public.monthly_budgets;
CREATE POLICY monthly_budgets_user_isolation_policy ON public.monthly_budgets FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS subjects_user_isolation_policy ON public.subjects;
CREATE POLICY subjects_user_isolation_policy ON public.subjects FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS study_units_user_isolation_policy ON public.study_units;
CREATE POLICY study_units_user_isolation_policy ON public.study_units FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS study_items_user_isolation_policy ON public.study_items;
CREATE POLICY study_items_user_isolation_policy ON public.study_items FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS goals_user_isolation_policy ON public.goals;
CREATE POLICY goals_user_isolation_policy ON public.goals FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS milestones_user_isolation_policy ON public.milestones;
CREATE POLICY milestones_user_isolation_policy ON public.milestones FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS calendar_events_user_isolation_policy ON public.calendar_events;
CREATE POLICY calendar_events_user_isolation_policy ON public.calendar_events FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');

DROP POLICY IF EXISTS journal_entries_user_isolation_policy ON public.journal_entries;
CREATE POLICY journal_entries_user_isolation_policy ON public.journal_entries FOR ALL USING (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role') WITH CHECK (auth.uid() = user_id OR (auth.jwt() ->> 'role') = 'service_role');
