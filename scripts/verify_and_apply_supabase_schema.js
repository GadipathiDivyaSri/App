const path = require('path');
const { supabase } = require(path.join(__dirname, '../backend/supabase_client.js'));

async function verifyTables() {
  const tables = [
    'profiles', 'subscriptions', 'payments', 'coupons', 'coupon_redemptions',
    'tasks', 'habits', 'habit_completions', 'expenses', 'monthly_budgets',
    'subjects', 'study_units', 'study_items', 'goals', 'milestones',
    'calendar_events', 'journal_entries'
  ];

  console.log('==================================================');
  console.log(' VERIFYING LIVE SUPABASE DATABASE TABLES & FIELDS');
  console.log('==================================================\n');

  let successCount = 0;
  let failCount = 0;

  for (const table of tables) {
    try {
      const { data, error } = await supabase.from(table).select('*').limit(1);
      if (error) {
        failCount++;
        console.error(` ❌ TABLE [${table}]: ERROR - ${error.message}`);
      } else {
        successCount++;
        const sampleKeys = data && data.length > 0 ? Object.keys(data[0]).join(', ') : '(Empty table - connected OK)';
        console.log(` ✅ TABLE [${table}]: CONNECTED OK | Sample Columns: [${sampleKeys}]`);
      }
    } catch (err) {
      failCount++;
      console.error(` ❌ TABLE [${table}]: EXCEPTION - ${err.message}`);
    }
  }

  console.log('\n==================================================');
  console.log(` SUMMARY: ${successCount} CONNECTED, ${failCount} FAILED`);
  console.log('==================================================\n');
}

verifyTables();
