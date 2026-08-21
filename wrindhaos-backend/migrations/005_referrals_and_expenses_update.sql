-- =============================================================================
-- WRINDHAOS DATABASE MIGRATION: 005_referrals_and_expenses_update.sql
-- Description: Adds referral tracking, rewards, date constraint enforcement,
--              expense income/expense transaction tracking, and cascade deletion.
-- =============================================================================

-- 1. Ensure referral_code exists on public.users and public.user_profiles
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'referral_code'
    ) THEN
        ALTER TABLE public.users ADD COLUMN referral_code VARCHAR(20) UNIQUE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'referred_by_code'
    ) THEN
        ALTER TABLE public.users ADD COLUMN referred_by_code VARCHAR(20);
    END IF;
END $$;

-- 2. Create Referrals Table
CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    referred_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    referral_code VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'QUALIFIED', 'REWARDED', 'EXPIRED', 'REJECTED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    qualified_at TIMESTAMPTZ,
    CONSTRAINT unique_referral_pair UNIQUE (referrer_user_id, referred_user_id)
);

-- 3. Create Referral Rewards Table (10% Next Billing Cycle Discount)
CREATE TABLE IF NOT EXISTS public.referral_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referral_id UUID REFERENCES public.referrals(id) ON DELETE CASCADE,
    referrer_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    discount_percentage INT NOT NULL DEFAULT 10 CHECK (discount_percentage BETWEEN 1 AND 100),
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'USED', 'EXPIRED')),
    applicable_billing_cycle INT DEFAULT 1,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ
);

-- 4. Ensure is_income and payment_method columns in expenses table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'is_income'
    ) THEN
        ALTER TABLE public.expenses ADD COLUMN is_income BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;
END $$;

-- 5. Indexes for fast lookup
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON public.users(referral_code);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred ON public.referrals(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_user ON public.referral_rewards(referrer_user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_user_income ON public.expenses(user_id, is_income);

-- 6. Row Level Security Policies
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_rewards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS referrals_owner_policy ON public.referrals;
CREATE POLICY referrals_owner_policy ON public.referrals 
FOR ALL USING (auth.uid() = referrer_user_id OR auth.uid() = referred_user_id);

DROP POLICY IF EXISTS referral_rewards_owner_policy ON public.referral_rewards;
CREATE POLICY referral_rewards_owner_policy ON public.referral_rewards 
FOR ALL USING (auth.uid() = referrer_user_id);
