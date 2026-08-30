-- =============================================================================
-- WRINDHAOS PRODUCTION DATABASE SCHEMA (PostgreSQL / Supabase RLS Ready)
-- =============================================================================

-- Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. USERS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('u_' || uuid_generate_v4()),
    username VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    is_email_verified BOOLEAN DEFAULT FALSE,
    focus_score INT DEFAULT 85,
    active_streak INT DEFAULT 1,
    is_premium BOOLEAN DEFAULT FALSE,
    referral_code VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code);

-- -----------------------------------------------------------------------------
-- 2. SUBSCRIPTIONS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subscriptions (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('sub_' || uuid_generate_v4()),
    user_id VARCHAR(64) UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan VARCHAR(20) DEFAULT 'free' CHECK (plan IN ('free', 'pro')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    payment_provider VARCHAR(50) DEFAULT 'NONE',
    transaction_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);

-- -----------------------------------------------------------------------------
-- 3. TASKS TABLE (To-Do, Eisenhower, Priority Matrix)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tasks (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('t_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(50) DEFAULT 'General',
    due_date_label VARCHAR(50) DEFAULT 'Today',
    is_completed BOOLEAN DEFAULT FALSE,
    priority INT DEFAULT 1 CHECK (priority BETWEEN 1 AND 4),
    quadrant INT DEFAULT 1 CHECK (quadrant BETWEEN 1 AND 4),
    due_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);

-- -----------------------------------------------------------------------------
-- 4. HABITS TABLE (Free Limit: Max 2 Active)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS habits (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('h_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    frequency VARCHAR(50) DEFAULT 'DAILY',
    streak INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits(user_id);

-- -----------------------------------------------------------------------------
-- 5. SUBJECTS TABLE (Free Limit: Max 2 Active)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subjects (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('sub_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50),
    instructor VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_subjects_user_id ON subjects(user_id);

-- -----------------------------------------------------------------------------
-- 6. EXPENSES TABLE (Pro Exclusive)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS expenses (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('e_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) DEFAULT 'General',
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    is_income BOOLEAN DEFAULT FALSE,
    payment_method VARCHAR(50) DEFAULT 'UPI',
    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);

-- -----------------------------------------------------------------------------
-- 7. JOURNAL & NOTES TABLE (Pro Exclusive)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS journal_entries (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('j_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    mood VARCHAR(50) DEFAULT 'Neutral',
    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_journal_user_id ON journal_entries(user_id);

-- -----------------------------------------------------------------------------
-- 8. GOALS TABLE (Pro Exclusive)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS goals (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('g_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    tier VARCHAR(20) DEFAULT 'short' CHECK (tier IN ('short', 'medium', 'long')),
    is_completed BOOLEAN DEFAULT FALSE,
    target_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_goals_user_id ON goals(user_id);

-- -----------------------------------------------------------------------------
-- 9. CAREER ROADMAP TABLE (Pro Exclusive)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS career_nodes (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('cn_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    section_key VARCHAR(50) DEFAULT 'GOAL',
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_career_user_id ON career_nodes(user_id);

-- -----------------------------------------------------------------------------
-- 10. COUPONS & COUPON USAGES
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS coupons (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('c_' || uuid_generate_v4()),
    code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) CHECK (discount_type IN ('percentage', 'fixed', 'free_trial')),
    discount_value NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    google_play_offer_id VARCHAR(100),
    start_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP WITH TIME ZONE,
    usage_limit INT DEFAULT 1000,
    per_user_limit INT DEFAULT 1,
    active BOOLEAN DEFAULT TRUE,
    campaign_source VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS coupon_usages (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('cu_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    coupon_id VARCHAR(64) NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL,
    purchase_amount NUMERIC(10, 2) DEFAULT 0.00,
    discount_applied NUMERIC(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 11. REFERRALS & TRACKING
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS referral_trackings (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('rt_' || uuid_generate_v4()),
    referrer_user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referred_user_id VARCHAR(64) UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referral_code VARCHAR(50) NOT NULL,
    reward_status VARCHAR(20) DEFAULT 'issued',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 12. ROW LEVEL SECURITY (RLS) POLICIES FOR SUPABASE
-- -----------------------------------------------------------------------------
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE career_nodes ENABLE ROW LEVEL SECURITY;

-- User Row Access Policies
CREATE POLICY user_isolation_policy ON tasks FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY habit_isolation_policy ON habits FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY subject_isolation_policy ON subjects FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY expense_isolation_policy ON expenses FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY journal_isolation_policy ON journal_entries FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY goal_isolation_policy ON goals FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY career_isolation_policy ON career_nodes FOR ALL USING (user_id = auth.uid()::text);
