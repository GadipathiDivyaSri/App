-- =============================================================================
-- WRINDHAOS - COMPLETE PRODUCTION SUPABASE / POSTGRESQL SCHEMA
-- Architecture: Supabase Auth + PostgreSQL + Row Level Security
-- Version: 2.0 (Includes Units, Topics, Priority Matrix & Eisenhower Matrix)
--
-- IMPORTANT:
-- 1. auth.users is the authentication source of truth.
-- 2. Passwords are NEVER stored in public tables.
-- 3. public.profiles.id always equals auth.users.id.
-- 4. Username and email are unique.
-- 5. Private productivity data is accessible only to its owner via RLS.
-- 6. Service-role operations (payments/admin/billing) must happen server-side.
-- =============================================================================

BEGIN;

-- =============================================================================
-- SECTION 0: EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =============================================================================
-- SECTION 1: ENUM TYPES
-- =============================================================================

DO $$ BEGIN
    CREATE TYPE subscription_plan AS ENUM ('free', 'premium', 'elite');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM (
        'active', 'cancelled', 'expired', 'grace_period', 'paused'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM (
        'pending', 'success', 'failed', 'refunded'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE habit_status AS ENUM ('active', 'paused', 'archived');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE study_status AS ENUM ('pending', 'in_progress', 'completed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE task_priority AS ENUM ('high', 'medium', 'low', 'none');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE eisenhower_quadrant AS ENUM (
        'q1_do_first',     -- Urgent & Important (Do First)
        'q2_schedule',     -- Not Urgent & Important (Schedule / Plan)
        'q3_delegate',     -- Urgent & Not Important (Delegate)
        'q4_eliminate'     -- Not Urgent & Not Important (Eliminate)
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =============================================================================
-- SECTION 2: CORE USER PROFILE
-- auth.users handles:
--   id, email, encrypted password, email confirmation, sessions
-- public.profiles handles:
--   username and application-specific user data
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    username VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,

    referral_code VARCHAR(50) NOT NULL UNIQUE,

    onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,

    terms_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    terms_accepted_at TIMESTAMPTZ,
    terms_version VARCHAR(50),

    privacy_policy_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    privacy_policy_accepted_at TIMESTAMPTZ,
    privacy_policy_version VARCHAR(50),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT profiles_username_length
        CHECK (char_length(username) BETWEEN 3 AND 50),

    CONSTRAINT profiles_username_format
        CHECK (username ~ '^[A-Za-z0-9_]+$'),

    CONSTRAINT profiles_terms_timestamp
        CHECK (
            (terms_accepted = FALSE)
            OR
            (terms_accepted = TRUE AND terms_accepted_at IS NOT NULL)
        )
);

CREATE INDEX IF NOT EXISTS idx_profiles_username
    ON public.profiles(username);

CREATE INDEX IF NOT EXISTS idx_profiles_email
    ON public.profiles(email);

CREATE INDEX IF NOT EXISTS idx_profiles_referral_code
    ON public.profiles(referral_code);

-- =============================================================================
-- SECTION 3: SUBSCRIPTIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL UNIQUE
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    plan subscription_plan NOT NULL DEFAULT 'free',
    status subscription_status NOT NULL DEFAULT 'active',

    billing_provider VARCHAR(50),

    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,

    auto_renew BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_status
    ON public.subscriptions(status);

-- =============================================================================
-- SECTION 4: PAYMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    subscription_id UUID
        REFERENCES public.subscriptions(id) ON DELETE SET NULL,

    provider VARCHAR(50) NOT NULL,

    transaction_id VARCHAR(255) UNIQUE,
    purchase_token TEXT UNIQUE,
    product_id VARCHAR(255),

    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',

    status payment_status NOT NULL DEFAULT 'pending',

    purchased_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_user
    ON public.payments(user_id);

CREATE INDEX IF NOT EXISTS idx_payments_subscription
    ON public.payments(subscription_id);

-- =============================================================================
-- SECTION 5: REFERRALS & REWARDS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    referrer_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    referred_user_id UUID NOT NULL UNIQUE
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    referral_code VARCHAR(50) NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'registered'
        CHECK (status IN ('registered', 'qualified', 'rewarded')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT referrals_no_self_referral
        CHECK (referrer_id <> referred_user_id)
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer
    ON public.referrals(referrer_id);

CREATE TABLE IF NOT EXISTS public.referral_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    referral_id UUID
        REFERENCES public.referrals(id) ON DELETE SET NULL,

    reward_type VARCHAR(50) NOT NULL,

    discount_percentage NUMERIC(5,2)
        CHECK (
            discount_percentage IS NULL
            OR (discount_percentage >= 0 AND discount_percentage <= 100)
        ),

    status VARCHAR(20) NOT NULL DEFAULT 'available'
        CHECK (status IN ('available', 'redeemed', 'expired')),

    expires_at TIMESTAMPTZ,
    redeemed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referral_rewards_user_status
    ON public.referral_rewards(user_id, status);

-- =============================================================================
-- SECTION 6: COUPONS & USAGES
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    code VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    description TEXT,

    discount_type VARCHAR(30) NOT NULL
        CHECK (discount_type IN ('percentage', 'fixed', 'free_trial')),

    discount_value NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (discount_value >= 0),

    google_play_offer_id VARCHAR(255),

    start_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,

    usage_limit INTEGER CHECK (usage_limit IS NULL OR usage_limit >= 1),
    per_user_limit INTEGER NOT NULL DEFAULT 1 CHECK (per_user_limit >= 1),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    campaign_source VARCHAR(100),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.coupon_usages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    coupon_id UUID NOT NULL
        REFERENCES public.coupons(id) ON DELETE CASCADE,

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    payment_id UUID
        REFERENCES public.payments(id) ON DELETE SET NULL,

    discount_applied NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (discount_applied >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_coupon_usages_user
    ON public.coupon_usages(user_id);

-- =============================================================================
-- SECTION 7: TASKS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50),

    priority task_priority NOT NULL DEFAULT 'medium',
    quadrant eisenhower_quadrant DEFAULT 'q1_do_first',

    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    due_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_user_due
    ON public.tasks(user_id, due_at);

CREATE INDEX IF NOT EXISTS idx_tasks_priority
    ON public.tasks(user_id, priority);

CREATE INDEX IF NOT EXISTS idx_tasks_quadrant
    ON public.tasks(user_id, quadrant);

-- =============================================================================
-- SECTION 7.1: PRIORITY MATRIX TABLE (High Priority, Medium Priority, Low Priority)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.priority_matrix (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    task_id UUID
        REFERENCES public.tasks(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    priority task_priority NOT NULL DEFAULT 'high', -- 'high', 'medium', 'low', 'none'

    due_date TIMESTAMPTZ,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_priority_matrix_user_priority
    ON public.priority_matrix(user_id, priority);

-- =============================================================================
-- SECTION 7.2: EISENHOWER MATRIX TABLE (Q1, Q2, Q3, Q4)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.eisenhower_matrix (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    task_id UUID
        REFERENCES public.tasks(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    quadrant eisenhower_quadrant NOT NULL DEFAULT 'q1_do_first',
    -- q1_do_first: Urgent & Important
    -- q2_schedule: Not Urgent & Important
    -- q3_delegate: Urgent & Not Important
    -- q4_eliminate: Not Urgent & Not Important

    is_urgent BOOLEAN NOT NULL DEFAULT TRUE,
    is_important BOOLEAN NOT NULL DEFAULT TRUE,

    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_eisenhower_matrix_user_quadrant
    ON public.eisenhower_matrix(user_id, quadrant);

-- =============================================================================
-- SECTION 8: HABITS & COMPLETIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    title VARCHAR(150) NOT NULL,
    category VARCHAR(50),

    frequency VARCHAR(30) NOT NULL DEFAULT 'daily'
        CHECK (frequency IN ('daily', 'weekly', 'custom')),

    selected_days JSONB NOT NULL DEFAULT '[]'::jsonb,

    interval_days INTEGER NOT NULL DEFAULT 1
        CHECK (interval_days >= 1),

    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    reminder_time TIME,

    color VARCHAR(20),
    icon_name VARCHAR(100),
    description TEXT,

    status habit_status NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_habits_user_status
    ON public.habits(user_id, status);

CREATE TABLE IF NOT EXISTS public.habit_completions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    habit_id UUID NOT NULL
        REFERENCES public.habits(id) ON DELETE CASCADE,

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    completion_date DATE NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'completed'
        CHECK (status IN ('completed', 'skipped')),

    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (habit_id, completion_date)
);

CREATE INDEX IF NOT EXISTS idx_habit_completions_user_date
    ON public.habit_completions(user_id, completion_date);

CREATE TABLE IF NOT EXISTS public.habit_pause_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    habit_id UUID NOT NULL
        REFERENCES public.habits(id) ON DELETE CASCADE,

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    paused_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resumed_at TIMESTAMPTZ,
    reason TEXT
);

-- =============================================================================
-- SECTION 9: CALENDAR
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    event_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,

    category VARCHAR(50),
    is_all_day BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT calendar_time_order
        CHECK (
            end_time IS NULL
            OR start_time IS NULL
            OR end_time > start_time
        )
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_user_date
    ON public.calendar_events(user_id, event_date);

-- =============================================================================
-- SECTION 10: ACADEMICS - SUBJECTS, UNITS & TOPICS HIERARCHY
-- =============================================================================

-- 10.1 SUBJECTS TABLE
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    name VARCHAR(150) NOT NULL,
    code VARCHAR(50),
    instructor VARCHAR(100),

    color VARCHAR(20),
    credits SMALLINT CHECK (credits IS NULL OR credits >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subjects_user
    ON public.subjects(user_id);

-- 10.2 STUDY UNITS TABLE (e.g. Unit 1: Thermodynamics, Unit 2: Kinematics)
CREATE TABLE IF NOT EXISTS public.study_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    subject_id UUID NOT NULL
        REFERENCES public.subjects(id) ON DELETE CASCADE,

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    unit_number INTEGER NOT NULL DEFAULT 1,
    title VARCHAR(255) NOT NULL,
    description TEXT,

    progress NUMERIC(5,2) NOT NULL DEFAULT 0.00
        CHECK (progress >= 0 AND progress <= 100),

    status study_status NOT NULL DEFAULT 'pending',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_study_units_subject
    ON public.study_units(subject_id);

-- 10.3 STUDY TOPICS TABLE (e.g. Carnot Engine, Entropy, Newton's Laws)
CREATE TABLE IF NOT EXISTS public.study_topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    unit_id UUID NOT NULL
        REFERENCES public.study_units(id) ON DELETE CASCADE,

    subject_id UUID NOT NULL
        REFERENCES public.subjects(id) ON DELETE CASCADE,

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    topic_number INTEGER NOT NULL DEFAULT 1,
    title VARCHAR(255) NOT NULL,
    description TEXT,

    estimated_minutes INTEGER DEFAULT 30
        CHECK (estimated_minutes IS NULL OR estimated_minutes >= 0),

    completed_minutes INTEGER NOT NULL DEFAULT 0
        CHECK (completed_minutes >= 0),

    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    status study_status NOT NULL DEFAULT 'pending',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_study_topics_unit
    ON public.study_topics(unit_id);

CREATE INDEX IF NOT EXISTS idx_study_topics_subject
    ON public.study_topics(subject_id);

-- 10.4 STUDY ITEMS (Assignments, Exams, Study Tasks)
CREATE TABLE IF NOT EXISTS public.study_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    subject_id UUID NOT NULL
        REFERENCES public.subjects(id) ON DELETE CASCADE,

    unit_id UUID
        REFERENCES public.study_units(id) ON DELETE SET NULL,

    topic_id UUID
        REFERENCES public.study_topics(id) ON DELETE SET NULL,

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    estimated_minutes INTEGER
        CHECK (estimated_minutes IS NULL OR estimated_minutes >= 0),

    completed_minutes INTEGER NOT NULL DEFAULT 0
        CHECK (completed_minutes >= 0),

    status study_status NOT NULL DEFAULT 'pending',
    priority task_priority NOT NULL DEFAULT 'medium',

    due_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_study_items_user
    ON public.study_items(user_id);

-- 10.5 TIMETABLE
CREATE TABLE IF NOT EXISTS public.timetable (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    subject_id UUID NOT NULL
        REFERENCES public.subjects(id) ON DELETE CASCADE,

    day_of_week SMALLINT NOT NULL
        CHECK (day_of_week BETWEEN 1 AND 7),

    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    room VARCHAR(100),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT timetable_time_order CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS idx_timetable_user_day
    ON public.timetable(user_id, day_of_week);

-- =============================================================================
-- SECTION 11: FINANCE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    title VARCHAR(150) NOT NULL,
    category VARCHAR(50),

    amount NUMERIC(12,2) NOT NULL
        CHECK (amount >= 0),

    transaction_type VARCHAR(20) NOT NULL
        CHECK (transaction_type IN ('expense', 'income')),

    payment_method VARCHAR(50),

    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_expenses_user_date
    ON public.expenses(user_id, occurred_at);

-- =============================================================================
-- SECTION 12: JOURNAL & NOTES
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    title VARCHAR(255),
    content TEXT NOT NULL,

    mood VARCHAR(50),
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_journal_entries_user_date
    ON public.journal_entries(user_id, entry_date);

CREATE TABLE IF NOT EXISTS public.notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    content TEXT,

    category VARCHAR(50),
    color VARCHAR(20),

    is_pinned BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notes_user
    ON public.notes(user_id);

-- =============================================================================
-- SECTION 13: FOCUS SESSIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.focus_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    duration_minutes INTEGER NOT NULL
        CHECK (duration_minutes > 0),

    session_type VARCHAR(50) NOT NULL DEFAULT 'pomodoro',

    focus_score_earned INTEGER NOT NULL DEFAULT 0,

    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_focus_sessions_user_date
    ON public.focus_sessions(user_id, completed_at);

-- =============================================================================
-- SECTION 14: GOALS & MILESTONES
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    tier VARCHAR(20) NOT NULL DEFAULT 'short'
        CHECK (tier IN ('short', 'medium', 'long')),

    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    target_date DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_goals_user
    ON public.goals(user_id);

CREATE TABLE IF NOT EXISTS public.milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    goal_id UUID NOT NULL
        REFERENCES public.goals(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    target_date DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_milestones_goal
    ON public.milestones(goal_id);

-- =============================================================================
-- SECTION 15: CAREER ROADMAP
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.career_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    section_key VARCHAR(50) NOT NULL DEFAULT 'goal',

    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    sort_order INTEGER NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_career_nodes_user
    ON public.career_nodes(user_id);

-- =============================================================================
-- SECTION 16: UPDATED_AT AUTOMATION
-- =============================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER trg_subscriptions_updated_at
BEFORE UPDATE ON public.subscriptions
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_tasks_updated_at ON public.tasks;
CREATE TRIGGER trg_tasks_updated_at
BEFORE UPDATE ON public.tasks
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_priority_matrix_updated_at ON public.priority_matrix;
CREATE TRIGGER trg_priority_matrix_updated_at
BEFORE UPDATE ON public.priority_matrix
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_eisenhower_matrix_updated_at ON public.eisenhower_matrix;
CREATE TRIGGER trg_eisenhower_matrix_updated_at
BEFORE UPDATE ON public.eisenhower_matrix
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_habits_updated_at ON public.habits;
CREATE TRIGGER trg_habits_updated_at
BEFORE UPDATE ON public.habits
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_calendar_updated_at ON public.calendar_events;
CREATE TRIGGER trg_calendar_updated_at
BEFORE UPDATE ON public.calendar_events
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_subjects_updated_at ON public.subjects;
CREATE TRIGGER trg_subjects_updated_at
BEFORE UPDATE ON public.subjects
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_study_units_updated_at ON public.study_units;
CREATE TRIGGER trg_study_units_updated_at
BEFORE UPDATE ON public.study_units
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_study_topics_updated_at ON public.study_topics;
CREATE TRIGGER trg_study_topics_updated_at
BEFORE UPDATE ON public.study_topics
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_study_items_updated_at ON public.study_items;
CREATE TRIGGER trg_study_items_updated_at
BEFORE UPDATE ON public.study_items
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_expenses_updated_at ON public.expenses;
CREATE TRIGGER trg_expenses_updated_at
BEFORE UPDATE ON public.expenses
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_journal_updated_at ON public.journal_entries;
CREATE TRIGGER trg_journal_updated_at
BEFORE UPDATE ON public.journal_entries
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_notes_updated_at ON public.notes;
CREATE TRIGGER trg_notes_updated_at
BEFORE UPDATE ON public.notes
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_goals_updated_at ON public.goals;
CREATE TRIGGER trg_goals_updated_at
BEFORE UPDATE ON public.goals
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_milestones_updated_at ON public.milestones;
CREATE TRIGGER trg_milestones_updated_at
BEFORE UPDATE ON public.milestones
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_career_nodes_updated_at ON public.career_nodes;
CREATE TRIGGER trg_career_nodes_updated_at
BEFORE UPDATE ON public.career_nodes
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =============================================================================
-- SECTION 17: AUTOMATIC PROFILE + FREE SUBSCRIPTION CREATION TRIGGER
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    generated_referral_code TEXT;
BEGIN
    generated_referral_code :=
        COALESCE(
            NULLIF(NEW.raw_user_meta_data ->> 'referral_code', ''),
            UPPER(SUBSTRING(REPLACE(gen_random_uuid()::TEXT, '-', '') FROM 1 FOR 10))
        );

    INSERT INTO public.profiles (
        id,
        username,
        name,
        email,
        referral_code,
        terms_accepted,
        terms_accepted_at,
        terms_version,
        privacy_policy_accepted,
        privacy_policy_accepted_at,
        privacy_policy_version
    )
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data ->> 'username',
        COALESCE(NULLIF(NEW.raw_user_meta_data ->> 'name', ''), 'WrindhaOS User'),
        NEW.email,
        generated_referral_code,
        COALESCE((NEW.raw_user_meta_data ->> 'terms_accepted')::BOOLEAN, FALSE),
        CASE
            WHEN COALESCE((NEW.raw_user_meta_data ->> 'terms_accepted')::BOOLEAN, FALSE)
            THEN NOW()
            ELSE NULL
        END,
        NEW.raw_user_meta_data ->> 'terms_version',
        COALESCE((NEW.raw_user_meta_data ->> 'privacy_policy_accepted')::BOOLEAN, FALSE),
        CASE
            WHEN COALESCE((NEW.raw_user_meta_data ->> 'privacy_policy_accepted')::BOOLEAN, FALSE)
            THEN NOW()
            ELSE NULL
        END,
        NEW.raw_user_meta_data ->> 'privacy_policy_version'
    );

    INSERT INTO public.subscriptions (
        user_id,
        plan,
        status
    )
    VALUES (
        NEW.id,
        'free',
        'active'
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- SECTION 18: ENABLE ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupon_usages ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.priority_matrix ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eisenhower_matrix ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_pause_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetable ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.career_nodes ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- SECTION 19: CORE PROFILE RLS
-- =============================================================================

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own"
ON public.profiles
FOR SELECT TO authenticated
USING (id = auth.uid());

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own"
ON public.profiles
FOR UPDATE TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- =============================================================================
-- SECTION 20: BUSINESS DATA RLS (Read-only for users)
-- =============================================================================

DROP POLICY IF EXISTS "subscriptions_select_own" ON public.subscriptions;
CREATE POLICY "subscriptions_select_own"
ON public.subscriptions
FOR SELECT TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "payments_select_own" ON public.payments;
CREATE POLICY "payments_select_own"
ON public.payments
FOR SELECT TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "referrals_select_own" ON public.referrals;
CREATE POLICY "referrals_select_own"
ON public.referrals
FOR SELECT TO authenticated
USING (
    referrer_id = auth.uid()
    OR referred_user_id = auth.uid()
);

DROP POLICY IF EXISTS "referral_rewards_select_own" ON public.referral_rewards;
CREATE POLICY "referral_rewards_select_own"
ON public.referral_rewards
FOR SELECT TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "coupon_usages_select_own" ON public.coupon_usages;
CREATE POLICY "coupon_usages_select_own"
ON public.coupon_usages
FOR SELECT TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "coupons_read_active" ON public.coupons;
CREATE POLICY "coupons_read_active"
ON public.coupons
FOR SELECT TO authenticated
USING (
    is_active = TRUE
    AND start_at <= NOW()
    AND (expires_at IS NULL OR expires_at > NOW())
);

-- =============================================================================
-- SECTION 21: PRIVATE OWNER-ONLY PRODUCTIVITY DATA RLS
-- (Strictly owner-only: zero admin visibility)
-- =============================================================================

-- TASKS
DROP POLICY IF EXISTS "tasks_owner_all" ON public.tasks;
CREATE POLICY "tasks_owner_all" ON public.tasks FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- PRIORITY MATRIX (High / Medium / Low / None)
DROP POLICY IF EXISTS "priority_matrix_owner_all" ON public.priority_matrix;
CREATE POLICY "priority_matrix_owner_all" ON public.priority_matrix FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- EISENHOWER MATRIX (Q1, Q2, Q3, Q4)
DROP POLICY IF EXISTS "eisenhower_matrix_owner_all" ON public.eisenhower_matrix;
CREATE POLICY "eisenhower_matrix_owner_all" ON public.eisenhower_matrix FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- HABITS & COMPLETIONS
DROP POLICY IF EXISTS "habits_owner_all" ON public.habits;
CREATE POLICY "habits_owner_all" ON public.habits FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "habit_completions_owner_all" ON public.habit_completions;
CREATE POLICY "habit_completions_owner_all" ON public.habit_completions FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "habit_pauses_owner_all" ON public.habit_pause_periods;
CREATE POLICY "habit_pauses_owner_all" ON public.habit_pause_periods FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- CALENDAR
DROP POLICY IF EXISTS "calendar_owner_all" ON public.calendar_events;
CREATE POLICY "calendar_owner_all" ON public.calendar_events FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- SUBJECTS, UNITS & TOPICS
DROP POLICY IF EXISTS "subjects_owner_all" ON public.subjects;
CREATE POLICY "subjects_owner_all" ON public.subjects FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "study_units_owner_all" ON public.study_units;
CREATE POLICY "study_units_owner_all" ON public.study_units FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "study_topics_owner_all" ON public.study_topics;
CREATE POLICY "study_topics_owner_all" ON public.study_topics FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "study_items_owner_all" ON public.study_items;
CREATE POLICY "study_items_owner_all" ON public.study_items FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "timetable_owner_all" ON public.timetable;
CREATE POLICY "timetable_owner_all" ON public.timetable FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- EXPENSES
DROP POLICY IF EXISTS "expenses_owner_all" ON public.expenses;
CREATE POLICY "expenses_owner_all" ON public.expenses FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- JOURNAL & NOTES
DROP POLICY IF EXISTS "journal_owner_all" ON public.journal_entries;
CREATE POLICY "journal_owner_all" ON public.journal_entries FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "notes_owner_all" ON public.notes;
CREATE POLICY "notes_owner_all" ON public.notes FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- FOCUS SESSIONS
DROP POLICY IF EXISTS "focus_owner_all" ON public.focus_sessions;
CREATE POLICY "focus_owner_all" ON public.focus_sessions FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- GOALS & MILESTONES
DROP POLICY IF EXISTS "goals_owner_all" ON public.goals;
CREATE POLICY "goals_owner_all" ON public.goals FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "milestones_owner_all" ON public.milestones;
CREATE POLICY "milestones_owner_all" ON public.milestones FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- CAREER NODES
DROP POLICY IF EXISTS "career_nodes_owner_all" ON public.career_nodes;
CREATE POLICY "career_nodes_owner_all" ON public.career_nodes FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

COMMIT;
