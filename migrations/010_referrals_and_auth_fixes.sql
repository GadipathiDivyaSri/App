-- =============================================================================
-- Migration 010: Referrals RLS Policy, Indexes & Profiles Password Hash Support
-- =============================================================================

-- 1. Ensure password_hash exists on profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- 2. Ensure referrals table has proper RLS policy for user data isolation
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS referrals_user_isolation_policy ON public.referrals;
CREATE POLICY referrals_user_isolation_policy ON public.referrals
    FOR ALL USING (
        auth.uid() = referrer_user_id 
        OR auth.uid() = referred_user_id 
        OR auth.role() = 'service_role'
    )
    WITH CHECK (
        auth.uid() = referrer_user_id 
        OR auth.uid() = referred_user_id 
        OR auth.role() = 'service_role'
    );

-- 3. Optimization Indexes for Referrals
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred ON public.referrals(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON public.referrals(code);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON public.referrals(status);
