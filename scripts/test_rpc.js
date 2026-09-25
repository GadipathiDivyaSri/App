const path = require('path');
const { supabase } = require(path.join(__dirname, '../backend/supabase_client.js'));

async function testRpc() {
  const ddl = `
  CREATE TABLE IF NOT EXISTS public.coupon_redemptions (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      coupon_id UUID NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
      user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
      redeemed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT uq_coupon_user UNIQUE (coupon_id, user_id)
  );
  `;

  try {
    const { data, error } = await supabase.rpc('exec_sql', { sql_query: ddl });
    if (error) {
      console.log('[RPC exec_sql NOT AVAILABLE]:', error.message);
    } else {
      console.log('[RPC exec_sql SUCCESS]:', data);
    }
  } catch (err) {
    console.log('[RPC EXCEPTION]:', err.message);
  }
}

testRpc();
