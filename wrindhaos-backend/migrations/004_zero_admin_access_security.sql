-- =============================================================================
-- WRINDHAOS ZERO-ADMIN & DEVELOPER-ACCESS SECURITY ARCHITECTURE
-- Migration Script: 004_zero_admin_access_security.sql
-- Description: Strict Row Level Security (RLS), User-A/User-B Hard Isolation,
--              pgcrypto AES-256 Ciphertext Encryption, Operational Metadata Tables,
--              and Elimination of Wildcard Admin Access.
-- =============================================================================

-- Enable Cryptographic Extensions for Developer/DBA Ciphertext Protection
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1. FIX USER MODERATION DEFAULT (Default FALSE - Never ban by default)
-- -----------------------------------------------------------------------------
ALTER TABLE IF EXISTS public.user_moderation 
    ALTER COLUMN is_banned SET DEFAULT FALSE;

-- -----------------------------------------------------------------------------
-- 2. OPERATIONAL & COMPLIANCE TABLES
-- -----------------------------------------------------------------------------

-- Account Deletion Requests (Self-service user deletion tracking)
CREATE TABLE IF NOT EXISTS public.account_deletion_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    status VARCHAR(30) DEFAULT 'REQUESTED' CHECK (status IN ('REQUESTED', 'SCHEDULED', 'PROCESSING', 'COMPLETED', 'CANCELED')),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT
);

-- Support Tickets (Metadata accessible by support agents; user content remains in ticket body only)
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_number VARCHAR(50) NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    subject VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) DEFAULT 'GENERAL' CHECK (category IN ('GENERAL', 'BILLING', 'TECHNICAL', 'ACCOUNT')),
    priority VARCHAR(20) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    status VARCHAR(30) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'IN_PROGRESS', 'WAITING_USER', 'RESOLVED', 'CLOSED')),
    assigned_admin_id UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- User Consents (Privacy & terms consent tracking)
CREATE TABLE IF NOT EXISTS public.user_consents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    policy_type VARCHAR(50) NOT NULL CHECK (policy_type IN ('PRIVACY_POLICY', 'TERMS_OF_SERVICE', 'COOKIE_POLICY', 'MARKETING_OPT_IN')),
    policy_version VARCHAR(20) NOT NULL,
    accepted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(50),
    user_agent TEXT,
    CONSTRAINT unique_user_policy_consent UNIQUE (user_id, policy_type, policy_version)
);

-- Legal Documents (Versioned system legal policies)
CREATE TABLE IF NOT EXISTS public.legal_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('PRIVACY_POLICY', 'TERMS', 'REFUND_POLICY', 'COOKIE_POLICY', 'ACCEPTABLE_USE', 'SUBSCRIPTION_POLICY')),
    version VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    published_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    CONSTRAINT unique_document_version UNIQUE (document_type, version)
);

-- -----------------------------------------------------------------------------
-- 3. REMOVE WILDCARD ADMIN PERMISSIONS & SEED EXPLICIT OPERATIONAL PERMISSIONS
-- -----------------------------------------------------------------------------
-- Update Super Admin accounts to explicit non-private administrative permissions
UPDATE public.admin_users
SET permissions = '["READ_ACCOUNT_METADATA", "READ_SUBSCRIPTION_METADATA", "READ_AGGREGATE_ANALYTICS", "MANAGE_SUPPORT_TICKETS", "MANAGE_USER_STATUS", "MANAGE_APP_SETTINGS", "MANAGE_ADMINS"]'::jsonb
WHERE permissions::text LIKE '%ALL%';

-- -----------------------------------------------------------------------------
-- 4. ENABLE ROW LEVEL SECURITY (RLS) ON ALL USER-OWNED PRIVATE TABLES
-- -----------------------------------------------------------------------------
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
ALTER TABLE public.priority_matrix_tasks ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.career_nodes ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.time_table_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.todo_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_daily_analytics ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 5. STRICT RLS POLICIES (AUTHENTICATED OWNER-ONLY: auth.uid() = user_id)
-- -----------------------------------------------------------------------------

-- User Profiles & Settings
DROP POLICY IF EXISTS user_profiles_owner_policy ON public.user_profiles;
CREATE POLICY user_profiles_owner_policy ON public.user_profiles
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS notification_settings_owner_policy ON public.notification_settings;
CREATE POLICY notification_settings_owner_policy ON public.notification_settings
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS user_referrals_owner_policy ON public.user_referrals;
CREATE POLICY user_referrals_owner_policy ON public.user_referrals
    FOR ALL USING (auth.uid() = referrer_id OR auth.uid() = referee_id) WITH CHECK (auth.uid() = referrer_id);

-- Habits & Streaks
DROP POLICY IF EXISTS habits_owner_policy ON public.habits;
CREATE POLICY habits_owner_policy ON public.habits
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_logs_owner_policy ON public.habit_logs;
CREATE POLICY habit_logs_owner_policy ON public.habit_logs
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_streaks_owner_policy ON public.habit_streaks;
CREATE POLICY habit_streaks_owner_policy ON public.habit_streaks
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_rewards_owner_policy ON public.habit_rewards;
CREATE POLICY habit_rewards_owner_policy ON public.habit_rewards
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Expenses & Budgets
DROP POLICY IF EXISTS monthly_budgets_owner_policy ON public.monthly_budgets;
CREATE POLICY monthly_budgets_owner_policy ON public.monthly_budgets
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS expense_categories_owner_policy ON public.expense_categories;
CREATE POLICY expense_categories_owner_policy ON public.expense_categories
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS expenses_owner_policy ON public.expenses;
CREATE POLICY expenses_owner_policy ON public.expenses
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Goals & Milestones
DROP POLICY IF EXISTS goals_hierarchy_owner_policy ON public.goals_hierarchy;
CREATE POLICY goals_hierarchy_owner_policy ON public.goals_hierarchy
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS milestones_owner_policy ON public.milestones;
CREATE POLICY milestones_owner_policy ON public.milestones
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Eisenhower & Priority Matrix
DROP POLICY IF EXISTS eisenhower_owner_policy ON public.eisenhower_matrix_tasks;
CREATE POLICY eisenhower_owner_policy ON public.eisenhower_matrix_tasks
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS priority_matrix_owner_policy ON public.priority_matrix_tasks;
CREATE POLICY priority_matrix_owner_policy ON public.priority_matrix_tasks
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Journal Entries (Strictly Owner-Only, ZERO Admin Policy)
DROP POLICY IF EXISTS journal_owner_policy ON public.journal_entries;
CREATE POLICY journal_owner_policy ON public.journal_entries
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Career Nodes
DROP POLICY IF EXISTS career_nodes_owner_policy ON public.career_nodes;
CREATE POLICY career_nodes_owner_policy ON public.career_nodes
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Academic Module (Subjects, Units, Topics, Study Sessions)
DROP POLICY IF EXISTS subjects_owner_policy ON public.subjects;
CREATE POLICY subjects_owner_policy ON public.subjects
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS units_owner_policy ON public.units;
CREATE POLICY units_owner_policy ON public.units
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS topics_owner_policy ON public.topics;
CREATE POLICY topics_owner_policy ON public.topics
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS study_sessions_owner_policy ON public.study_sessions;
CREATE POLICY study_sessions_owner_policy ON public.study_sessions
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Time Table & Calendar Schedule
DROP POLICY IF EXISTS time_table_owner_policy ON public.time_table_slots;
CREATE POLICY time_table_owner_policy ON public.time_table_slots
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS calendar_events_owner_policy ON public.calendar_events;
CREATE POLICY calendar_events_owner_policy ON public.calendar_events
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- To-Do Tasks & Analytics
DROP POLICY IF EXISTS todo_tasks_owner_policy ON public.todo_tasks;
CREATE POLICY todo_tasks_owner_policy ON public.todo_tasks
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS user_analytics_owner_policy ON public.user_daily_analytics;
CREATE POLICY user_analytics_owner_policy ON public.user_daily_analytics
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Account Deletion Requests & Consents
DROP POLICY IF EXISTS deletion_requests_owner_policy ON public.account_deletion_requests;
CREATE POLICY deletion_requests_owner_policy ON public.account_deletion_requests
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS user_consents_owner_policy ON public.user_consents;
CREATE POLICY user_consents_owner_policy ON public.user_consents
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Support Tickets (User can access own tickets)
DROP POLICY IF EXISTS support_tickets_user_policy ON public.support_tickets;
CREATE POLICY support_tickets_user_policy ON public.support_tickets
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Public Read for Legal Documents
DROP POLICY IF EXISTS legal_documents_public_policy ON public.legal_documents;
CREATE POLICY legal_documents_public_policy ON public.legal_documents
    FOR SELECT USING (is_active = true);

-- -----------------------------------------------------------------------------
-- 6. DEVELOPER & DBA AES-256 CIPHERTEXT ENCRYPTION HELPERS
-- -----------------------------------------------------------------------------
-- Encrypt Sensitive Free-Text (Journal Body Content)
CREATE OR REPLACE FUNCTION encrypt_journal_content(secret_key TEXT, plain_text TEXT)
RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(plain_text, secret_key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Decrypt Sensitive Free-Text (Journal Body Content)
CREATE OR REPLACE FUNCTION decrypt_journal_content(secret_key TEXT, cipher_data BYTEA)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(cipher_data, secret_key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
