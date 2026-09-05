const path = require('path');
const fs = require('fs');

// Try loading dotenv manually without external dependencies
try {
  const envPath = path.join(__dirname, '.env');
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf8');
    envContent.split(/\r?\n/).forEach((line) => {
      const match = line.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/);
      if (match) {
        const key = match[1];
        let value = match[2] || '';
        if (value.startsWith('"') && value.endsWith('"')) value = value.slice(1, -1);
        if (value.startsWith("'") && value.endsWith("'")) value = value.slice(1, -1);
        process.env[key] = value.trim();
      }
    });
  }
} catch (e) {}

let createClient = null;
try {
  createClient = require('@supabase/supabase-js').createClient;
} catch (e) {
  try {
    createClient = require(path.join(__dirname, 'node_modules', '@supabase', 'supabase-js')).createClient;
  } catch (err) {}
}

const supabaseUrl = process.env.SUPABASE_URL || '';
let rawKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY || process.env.SUPABASE_ANON_KEY || '';
if (rawKey.includes('=')) {
  const parts = rawKey.split('=');
  rawKey = parts[parts.length - 1].trim();
}
const supabaseKey = rawKey.trim();

const isConfigured = supabaseUrl.startsWith('https://') && supabaseKey.startsWith('eyJ') && !supabaseUrl.includes('your-project-ref');

let supabase = null;
if (isConfigured && createClient) {
  try {
    supabase = createClient(supabaseUrl, supabaseKey, {
      auth: {
        autoRefreshToken: true,
        persistSession: false,
      },
    });
    console.log('✅ Supabase PostgreSQL Database connected successfully: ' + supabaseUrl);
  } catch (err) {
    console.warn('⚠️ Could not initialize Supabase client:', err.message);
  }
} else {
  console.log('ℹ️ Supabase not yet configured. Using local persistent JSON storage (backend/data/db.json).');
}

module.exports = {
  supabase,
  isConfigured: () => !!supabase,
};
