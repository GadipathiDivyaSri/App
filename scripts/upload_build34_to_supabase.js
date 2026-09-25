const fs = require('fs');
const path = require('path');
const { supabase } = require('../backend/supabase_client');

async function uploadBinaries() {
  console.log('==================================================');
  console.log(' UPLOADING BUILD 34 BINARIES TO SUPABASE STORAGE');
  console.log('==================================================\n');

  if (!supabase) {
    console.error('❌ Supabase client not initialized.');
    process.exit(1);
  }

  const apkPath = 'C:\\Users\\ushma\\.gemini\\antigravity\\brain\\97162d54-0326-4a3b-8680-6508b970e95d\\WrindhaOS-v1.1.1-build34.apk';
  const aabPath = 'C:\\Users\\ushma\\.gemini\\antigravity\\brain\\97162d54-0326-4a3b-8680-6508b970e95d\\WrindhaOS-v1.1.1-build34.aab';

  // Ensure bucket 'apks' exists and is public
  try {
    const { data: buckets, error: bErr } = await supabase.storage.listBuckets();
    if (bErr) console.warn('Bucket list notice:', bErr.message);

    const exists = (buckets || []).some(b => b.name === 'apks');
    if (!exists) {
      console.log('Creating public bucket "apks"...');
      await supabase.storage.createBucket('apks', { public: true });
    }
  } catch (err) {
    console.warn('Bucket setup notice:', err.message);
  }

  // Upload APK
  if (fs.existsSync(apkPath)) {
    console.log(`⏳ Uploading APK (${(fs.statSync(apkPath).size / 1024 / 1024).toFixed(2)} MB)...`);
    const apkBuffer = fs.readFileSync(apkPath);
    const { data, error } = await supabase.storage
      .from('apks')
      .upload('WrindhaOS-v1.1.1-build34.apk', apkBuffer, {
        contentType: 'application/vnd.android.package-archive',
        upsert: true,
      });

    if (error) {
      console.error('❌ APK Upload Error:', error.message);
    } else {
      console.log('✅ APK Uploaded Successfully!');
      const { data: publicUrlData } = supabase.storage.from('apks').getPublicUrl('WrindhaOS-v1.1.1-build34.apk');
      console.log('🔗 APK Public URL:', publicUrlData.publicUrl);
    }
  } else {
    console.error('❌ APK File not found at:', apkPath);
  }

  // Upload AAB
  if (fs.existsSync(aabPath)) {
    console.log(`\n⏳ Uploading AAB (${(fs.statSync(aabPath).size / 1024 / 1024).toFixed(2)} MB)...`);
    const aabBuffer = fs.readFileSync(aabPath);
    const { data, error } = await supabase.storage
      .from('apks')
      .upload('WrindhaOS-v1.1.1-build34.aab', aabBuffer, {
        contentType: 'application/octet-stream',
        upsert: true,
      });

    if (error) {
      console.error('❌ AAB Upload Error:', error.message);
    } else {
      console.log('✅ AAB Uploaded Successfully!');
      const { data: publicUrlData } = supabase.storage.from('apks').getPublicUrl('WrindhaOS-v1.1.1-build34.aab');
      console.log('🔗 AAB Public URL:', publicUrlData.publicUrl);
    }
  } else {
    console.error('❌ AAB File not found at:', aabPath);
  }

  console.log('\n==================================================');
}

uploadBinaries();
