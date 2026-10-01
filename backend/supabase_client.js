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

const supabaseUrl = process.env.SUPABASE_URL || 'https://hkeyywopbkmlclsealbz.supabase.co';
let rawKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrZXl5d29wYmttbGNsc2VhbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODI3MTIxOSwiZXhwIjoyMTAzODQ3MjE5fQ.rAJQONxcr0PgCT-59ZfsjoyojY4-_g5aTaH2zwIntAg';
if (rawKey.includes('=')) {
  const parts = rawKey.split('=');
  rawKey = parts[parts.length - 1].trim();
}
const supabaseKey = rawKey.trim();

let rawAnonKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrZXl5d29wYmttbGNsc2VhbGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgyNzEyMTksImV4cCI6MjEwMzg0NzIxOX0.axTZ1vLqZhquSfDhDXwIg4Sf2nioT8ZFjve39gr9QmY';
if (rawAnonKey.includes('=')) {
  const parts = rawAnonKey.split('=');
  rawAnonKey = parts[parts.length - 1].trim();
}
const supabaseAnonKey = rawAnonKey.trim();

const isConfigured = supabaseUrl.startsWith('https://') && supabaseKey.startsWith('eyJ') && !supabaseUrl.includes('your-project-ref');

let supabase = null;
let anonClient = null;

if (isConfigured && createClient) {
  try {
    supabase = createClient(supabaseUrl, supabaseKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });
    console.log('✅ Supabase PostgreSQL Database connected successfully: ' + supabaseUrl);
  } catch (err) {
    console.warn('⚠️ Could not initialize Supabase admin client:', err.message);
  }

  try {
    if (supabaseAnonKey) {
      anonClient = createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      });
    }
  } catch (err) {
    console.warn('⚠️ Could not initialize Supabase anon client:', err.message);
  }
} else {
  console.error('❌ ERROR: Supabase Cloud Database credentials are missing or unconfigured.');
}

module.exports = {
  supabase,
  anonClient: anonClient || supabase,
  isConfigured: () => !!supabase,
  supabaseUrl,
  supabaseKey,
  supabaseAnonKey,
};
