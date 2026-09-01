-- =============================================================================
-- WRINDHAOS PRODUCTION SUPABASE / POSTGRESQL DATABASE SCHEMA
-- Complete 25-Table Schema with Foreign Keys, Constraints, Indexes & RLS
-- =============================================================================

-- 1. Enable UUID Extension
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
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code);

-- -----------------------------------------------------------------------------
-- 2. OTP STORE TABLE (Auto-expiring 10-Minute Codes)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS otp_store (
    email VARCHAR(150) PRIMARY KEY,
    code VARCHAR(10) NOT NULL,
    type VARCHAR(30) DEFAULT 'register', -- 'register', 'reset'
    attempts INT DEFAULT 0,
    max_attempts INT DEFAULT 5,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    pending_user JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_otp_store_expires ON otp_store(expires_at);

-- -----------------------------------------------------------------------------
-- 3. SUBSCRIPTIONS TABLE (Free vs Pro)
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
    last_billing_amount NUMERIC(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);

-- -----------------------------------------------------------------------------
-- 4. PAYMENT HISTORY & INVOICES
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payment_history (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('pay_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id VARCHAR(64) REFERENCES subscriptions(id) ON DELETE SET NULL,
    invoice_number VARCHAR(100) UNIQUE,
    amount NUMERIC(10, 2) NOT NULL,
    discount_applied NUMERIC(10, 2) DEFAULT 0.00,
    payment_provider VARCHAR(50) DEFAULT 'GOOGLE_PLAY',
    transaction_id VARCHAR(100),
    payment_status VARCHAR(20) DEFAULT 'success' CHECK (payment_status IN ('success', 'pending', 'failed', 'refunded')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_history_user_id ON payment_history(user_id);

-- -----------------------------------------------------------------------------
-- 5. TASKS TABLE (To-Do & Eisenhower Priority Matrix Q1-Q4)
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
CREATE INDEX IF NOT EXISTS idx_tasks_quadrant ON tasks(quadrant);

-- -----------------------------------------------------------------------------
-- 6. HABITS TABLE (Free Limit: Max 2 Active, Pro: Unlimited)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS habits (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('h_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) DEFAULT 'General',
    frequency VARCHAR(50) DEFAULT 'DAILY', -- 'DAILY', 'WEEKDAYS', 'WEEKENDS', 'CUSTOM', 'CUSTOM_INTERVAL', 'WEEKLY'
    selected_days JSONB DEFAULT '[]'::jsonb, -- e.g. [1, 3, 5] for Mon, Wed, Fri
    interval_days INT DEFAULT 1,
    start_date DATE DEFAULT CURRENT_DATE,
    time VARCHAR(30) DEFAULT '08:00 AM',
    color VARCHAR(30) DEFAULT '#10B981',
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'archived')),
    description TEXT,
    icon_name VARCHAR(50) DEFAULT 'repeat',
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits(user_id);
CREATE INDEX IF NOT EXISTS idx_habits_status ON habits(status);

-- -----------------------------------------------------------------------------
-- 6.1 HABIT COMPLETIONS TABLE (Persistent History & Unique Check-in Constraint)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS habit_completions (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('hc_' || uuid_generate_v4()),
    habit_id VARCHAR(64) NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    completion_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('completed', 'skipped')),
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_habit_user_date UNIQUE (habit_id, user_id, completion_date)
);

CREATE INDEX IF NOT EXISTS idx_habit_completions_user_date ON habit_completions(user_id, completion_date);
CREATE INDEX IF NOT EXISTS idx_habit_completions_habit_id ON habit_completions(habit_id);

-- -----------------------------------------------------------------------------
-- 6.2 HABIT PAUSE PERIODS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS habit_pause_periods (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('hpp_' || uuid_generate_v4()),
    habit_id VARCHAR(64) NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    paused_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resumed_at TIMESTAMP WITH TIME ZONE,
    reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_habit_pause_habit_id ON habit_pause_periods(habit_id);

-- -----------------------------------------------------------------------------
-- 7. CALENDAR & SCHEDULE EVENTS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS calendar_events (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('cal_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    start_time VARCHAR(20) DEFAULT '09:00',
    end_time VARCHAR(20) DEFAULT '10:00',
    category VARCHAR(50) DEFAULT 'General',
    is_all_day BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_calendar_user_date ON calendar_events(user_id, date);

-- -----------------------------------------------------------------------------
-- 8. SUBJECTS & STUDY PLANNER
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subjects (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('sub_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50),
    instructor VARCHAR(100),
    color VARCHAR(30) DEFAULT '#3B82F6',
    credits INT DEFAULT 3,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_subjects_user_id ON subjects(user_id);

-- -----------------------------------------------------------------------------
-- 8.1 STUDY UNITS / ITEMS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS study_items (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('si_' || uuid_generate_v4()),
    subject_id VARCHAR(64) NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    estimated_hours NUMERIC(5, 2) DEFAULT 2.0,
    completed_hours NUMERIC(5, 2) DEFAULT 0.0,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    priority INT DEFAULT 1 CHECK (priority BETWEEN 1 AND 4),
    due_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_study_items_subject ON study_items(subject_id);

-- -----------------------------------------------------------------------------
-- 8.2 TIMETABLE MATRIX TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS timetable (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('tt_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_id VARCHAR(64) NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1 = Mon, 7 = Sun
    start_time VARCHAR(20) NOT NULL,
    end_time VARCHAR(20) NOT NULL,
    room VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_timetable_user ON timetable(user_id);

-- -----------------------------------------------------------------------------
-- 9. EXPENSES TABLE (Financial Wellness)
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
-- 10. JOURNAL ENTRIES & PERSONAL NOTES
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

CREATE TABLE IF NOT EXISTS notes (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('n_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    category VARCHAR(50) DEFAULT 'General',
    color VARCHAR(30) DEFAULT '#FEF3C7',
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);

-- -----------------------------------------------------------------------------
-- 11. FOCUS TIMER SESSIONS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS focus_sessions (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('fs_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    duration_minutes INT NOT NULL DEFAULT 25,
    session_type VARCHAR(50) DEFAULT 'pomodoro',
    focus_score_earned INT DEFAULT 5,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_focus_sessions_user ON focus_sessions(user_id);

-- -----------------------------------------------------------------------------
-- 12. GOALS & MILESTONES
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

CREATE TABLE IF NOT EXISTS milestones (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('m_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_id VARCHAR(64) REFERENCES goals(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    date_achieved TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_milestones_user_id ON milestones(user_id);

-- -----------------------------------------------------------------------------
-- 13. CAREER ROADMAP & SKILL NODES
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
-- 14. COUPONS & COUPON USAGES
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

CREATE INDEX IF NOT EXISTS idx_coupon_usages_user ON coupon_usages(user_id);

-- -----------------------------------------------------------------------------
-- 15. REFERRALS & 10% SINGLE-BILLING REWARD REVENUE SYSTEM
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS referral_codes (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('ref_' || uuid_generate_v4()),
    user_id VARCHAR(64) UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referral_code VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    total_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON referral_codes(referral_code);

CREATE TABLE IF NOT EXISTS referral_trackings (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('rt_' || uuid_generate_v4()),
    referrer_user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referred_user_id VARCHAR(64) UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referral_code VARCHAR(50) NOT NULL,
    first_purchase_status VARCHAR(20) DEFAULT 'pending' CHECK (first_purchase_status IN ('pending', 'completed')),
    first_purchase_date TIMESTAMP WITH TIME ZONE,
    purchase_amount NUMERIC(10, 2) DEFAULT 0.00,
    referrer_reward_status VARCHAR(20) DEFAULT 'issued',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_referral_trackings_referrer ON referral_trackings(referrer_user_id);
CREATE INDEX IF NOT EXISTS idx_referral_trackings_referred ON referral_trackings(referred_user_id);

-- One-Time 10% Discount on Next Billing Only Table
CREATE TABLE IF NOT EXISTS referral_rewards (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('rr_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    earned_from_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    discount_percentage INT DEFAULT 10,
    one_time_next_billing_only BOOLEAN DEFAULT TRUE,
    status VARCHAR(20) DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE', 'REDEEMED', 'EXPIRED')),
    redeemed_at TIMESTAMP WITH TIME ZONE,
    redeemed_for_amount NUMERIC(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_referral_rewards_user ON referral_rewards(user_id, status);

-- -----------------------------------------------------------------------------
-- 16. NOTIFICATIONS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(64) PRIMARY KEY DEFAULT ('notif_' || uuid_generate_v4()),
    user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'GENERAL',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);

-- -----------------------------------------------------------------------------
-- 17. SUPABASE ROW LEVEL SECURITY (RLS) POLICIES
-- -----------------------------------------------------------------------------
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_pause_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE career_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupon_usages ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Dynamic RLS Policies
CREATE POLICY user_self_policy ON users FOR ALL USING (id = auth.uid()::text);
CREATE POLICY subscriptions_isolation_policy ON subscriptions FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY payment_history_isolation_policy ON payment_history FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY tasks_isolation_policy ON tasks FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY habits_isolation_policy ON habits FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY habit_completions_isolation_policy ON habit_completions FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY habit_pause_isolation_policy ON habit_pause_periods FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY calendar_isolation_policy ON calendar_events FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY subjects_isolation_policy ON subjects FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY study_items_isolation_policy ON study_items FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY timetable_isolation_policy ON timetable FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY expenses_isolation_policy ON expenses FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY journal_isolation_policy ON journal_entries FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY notes_isolation_policy ON notes FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY focus_sessions_isolation_policy ON focus_sessions FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY goals_isolation_policy ON goals FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY milestones_isolation_policy ON milestones FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY career_nodes_isolation_policy ON career_nodes FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY coupon_usages_isolation_policy ON coupon_usages FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY referral_rewards_isolation_policy ON referral_rewards FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY notifications_isolation_policy ON notifications FOR ALL USING (user_id = auth.uid()::text);
