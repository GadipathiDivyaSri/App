const path = require('path');
const { Client } = require(path.join(__dirname, '../backend/node_modules/pg'));
const connectionString = 'postgresql://postgres.hkeyywopbkmlclsealbz:yb8J3XQGAcuh2SXc@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres';

async function addColumn() {
  const c = new Client({ connectionString, ssl: { rejectUnauthorized: false } });
  try {
    await c.connect();
    console.log('Connected to Supabase PostgreSQL database.');

    await c.query(`
      ALTER TABLE public.profiles 
      ADD COLUMN IF NOT EXISTS new_password TEXT;
    `);
    console.log(' ✅ Successfully added new_password column to public.profiles table!');
  } catch (err) {
    console.error(' ❌ Error adding new_password column:', err.message);
  } finally {
    await c.end();
  }
}

addColumn();
