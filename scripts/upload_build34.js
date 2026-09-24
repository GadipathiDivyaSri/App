const fs = require('fs');
const path = require('path');
const { createClient } = require(path.join(__dirname, '../backend/node_modules/@supabase/supabase-js'));

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://hkeyywopbkmlclsealbz.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrZXl5d29wYmttbGNsc2VhbGJ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MTEzNTIxOCwiZXhwIjoyMDU2NzExMjE4fQ.D6kGkGg6f8Z2c3-9Z9_Z_Z_Z_Z_Z_Z_Z';

// Read from backend/db_manager.js or env if available
const dbManagerPath = path.join(__dirname, '../backend/db_manager.js');
let serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!serviceKey && fs.existsSync(dbManagerPath)) {
  const content = fs.readFileSync(dbManagerPath, 'utf8');
  const match = content.match(/SUPABASE_SERVICE_ROLE_KEY\s*=\s*['"]([^'"]+)['"]/);
  if (match) serviceKey = match[1];
}

if (!serviceKey) {
  const envPath = path.join(__dirname, '../backend/.env');
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf8');
    const match = envContent.match(/SUPABASE_SERVICE_ROLE_KEY=([^\r\n]+)/);
    if (match) serviceKey = match[1].trim();
  }
}

console.log('[SUPABASE UPLOAD] Service Key Found:', !!serviceKey);

const supabase = createClient(SUPABASE_URL, serviceKey || SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

async function uploadFile(fileName, filePath) {
  const fileBuffer = fs.readFileSync(filePath);
  console.log(`[UPLOADING] ${fileName} (${(fileBuffer.length / 1024 / 1024).toFixed(2)} MB)...`);

  const { data, error } = await supabase.storage.from('releases').upload(fileName, fileBuffer, {
    contentType: fileName.endsWith('.apk') ? 'application/vnd.android.package-archive' : 'application/octet-stream',
    upsert: true,
  });

  if (error) {
    console.error(`[UPLOAD ERROR] ${fileName}:`, error.message);
    return null;
  }

  const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/releases/${fileName}`;
  console.log(`[UPLOAD SUCCESS] ${fileName} -> ${publicUrl}`);
  return publicUrl;
}

async function main() {
  const apkPath = 'C:/Users/ushma/.gemini/antigravity/brain/97162d54-0326-4a3b-8680-6508b970e95d/WrindhaOS-v1.1.1-build34.apk';
  const aabPath = 'C:/Users/ushma/.gemini/antigravity/brain/97162d54-0326-4a3b-8680-6508b970e95d/WrindhaOS-v1.1.1-build34.aab';

  const apkUrl = await uploadFile('WrindhaOS-v1.1.1-build34.apk', apkPath);
  const aabUrl = await uploadFile('WrindhaOS-v1.1.1-build34.aab', aabPath);

  console.log('\n========================================');
  console.log('BUILD 34 PUBLIC DOWNLOAD LINKS:');
  console.log('APK:', apkUrl);
  console.log('AAB:', aabUrl);
  console.log('========================================\n');
}

main().catch(err => {
  console.error('[FATAL ERROR]:', err);
  process.exit(1);
});
