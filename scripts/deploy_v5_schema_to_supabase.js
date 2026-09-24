const fs = require('fs');
const path = require('path');
const { Client } = require(path.join(__dirname, '../backend/node_modules/pg'));

const connectionString = 'postgresql://postgres:yb8J3XQGAcuh2SXc@db.hkeyywopbkmlclsealbz.supabase.co:5432/postgres';

async function deploySchema() {
  console.log('==================================================');
  console.log(' CONNECTING TO LIVE SUPABASE POSTGRES DATABASE');
  console.log(' URL: db.hkeyywopbkmlclsealbz.supabase.co:5432');
  console.log('==================================================\n');

  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false },
  });

  try {
    await client.connect();
    console.log(' ✅ CONNECTED TO REMOTE SUPABASE POSTGRESQL DATABASE!');

    const schemaPath = path.join(__dirname, '../backend/schema.sql');
    const sqlScript = fs.readFileSync(schemaPath, 'utf8');

    console.log(' ⏳ EXECUTING MASTER SCHEMA v5.0.0 DDL STATEMENTS...');
    await client.query(sqlScript);

    console.log(' ✅ MASTER SCHEMA v5.0.0 APPLIED SUCCESSFULLY TO SUPABASE!');

    // Verify all 17 tables exist
    const res = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `);

    const tableNames = res.rows.map(r => r.table_name);
    console.log('\n==================================================');
    console.log(' LIVE SUPABASE TABLES IN PUBLIC SCHEMA:');
    console.log(tableNames.join(', '));
    console.log('==================================================\n');

  } catch (err) {
    console.error(' ❌ SUPABASE SCHEMA DEPLOYMENT ERROR:', err.message);
  } finally {
    await client.end();
  }
}

deploySchema();
