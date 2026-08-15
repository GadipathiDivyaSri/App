-- WrindhaOS Complete Supabase PostgreSQL Schema Migration
-- Enables UUID generation and Row Level Security (RLS) policies

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. USERS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name VARCHAR(255),
  email VARCHAR(255) UNIQUE,
  phone_number VARCHAR(50) UNIQUE,
  profile_image TEXT,
  subscription_plan VARCHAR(50) NOT NULL DEFAULT 'FREE', -- FREE | PREMIUM
  subscription_status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | CANCELLED | EXPIRED | GRACE_PERIOD | ON_HOLD
  ads_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 2. USER AUTH IDENTITIES TABLE (Account Linking)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 3. SUBSCRIPTIONS TABLE (Google Play Billing Only)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  provider VARCHAR(50) NOT NULL DEFAULT 'google_play',
  product_id VARCHAR(255) NOT NULL,
  purchase_token TEXT NOT NULL UNIQUE,
  order_id VARCHAR(255),
  status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | CANCELLED | EXPIRED | PAUSED | PENDING | GRACE_PERIOD | ON_HOLD
  plan VARCHAR(50) NOT NULL DEFAULT 'PREMIUM',
  auto_renewing BOOLEAN NOT NULL DEFAULT TRUE,
  price VARCHAR(50),
  currency VARCHAR(10),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  current_period_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  current_period_end TIMESTAMPTZ NOT NULL,
  cancelled_at TIMESTAMPTZ,
  expired_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 4. PLANS & ENTITLEMENT FEATURES TABLES
-- -----------------------------------------------------------------------------
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
  -- FREE Plan Limits
  ('FREE', 'EISENHOWER_MATRIX', TRUE, NULL),
  ('FREE', 'CALENDAR', TRUE, NULL),
  ('FREE', 'TODO', TRUE, NULL),
  ('FREE', 'HABITS', TRUE, 2),
  ('FREE', 'SUBJECTS', TRUE, 2),
  ('FREE', 'GOALS', TRUE, 2),
  ('FREE', 'CAREER_TRAJECTORY', TRUE, NULL),
  ('FREE', 'ANALYTICS', TRUE, NULL),
  ('FREE', 'FOCUS_CENTRE', TRUE, NULL),

  -- PREMIUM Plan Limits (All Unlimited)
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

-- -----------------------------------------------------------------------------
-- 5. USER DATA TABLES (Todos, Habits, Subjects, Calendar, Eisenhower)
-- -----------------------------------------------------------------------------
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

CREATE TABLE IF NOT EXISTS public.habits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  frequency VARCHAR(50) DEFAULT 'Daily',
  target_days INT DEFAULT 7,
  current_streak INT DEFAULT 0,
  is_completed_today BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.habit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  completed_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_habit_log_date UNIQUE(habit_id, completed_date)
);

CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  code VARCHAR(50),
  mastery_percentage INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.calendar_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  location VARCHAR(255),
  reminder BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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

-- -----------------------------------------------------------------------------
-- 6. DEVICE TOKENS & AUDIT LOGS TABLES
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform VARCHAR(50) DEFAULT 'flutter_android',
  device_id VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  event_type VARCHAR(100) NOT NULL,
  details JSONB,
  ip_address VARCHAR(50),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 7. INDEXES FOR HIGH PERFORMANCE
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone_number);
CREATE INDEX IF NOT EXISTS idx_identities_user ON public.user_auth_identities(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_token ON public.subscriptions(purchase_token);
CREATE INDEX IF NOT EXISTS idx_todos_user ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_habits_user ON public.habits(user_id);
CREATE INDEX IF NOT EXISTS idx_subjects_user ON public.subjects(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_user ON public.calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_eisenhower_user ON public.eisenhower_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tokens_user ON public.device_tokens(user_id);

-- -----------------------------------------------------------------------------
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- -----------------------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_auth_identities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eisenhower_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- Base RLS Policy Example: Users can only select/update their own records
CREATE POLICY user_isolation_policy ON public.todos
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY habits_isolation_policy ON public.habits
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY subjects_isolation_policy ON public.subjects
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY calendar_isolation_policy ON public.calendar_events
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY eisenhower_isolation_policy ON public.eisenhower_tasks
  FOR ALL USING (auth.uid() = user_id);
