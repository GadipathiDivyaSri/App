const fs = require('fs');
const path = require('path');
const { supabase } = require('../backend/supabase_client');

async function uploadBinaries() {
  console.log('==================================================');
  console.log(' UPLOADING BUILD 36 BINARIES TO SUPABASE STORAGE');
  console.log('==================================================\n');

  if (!supabase) {
    console.error('❌ Supabase client not initialized.');
    process.exit(1);
  }

  const apkPath = 'C:\\Users\\ushma\\.gemini\\antigravity\\brain\\97162d54-0326-4a3b-8680-6508b970e95d\\WrindhaOS-v1.1.1-build36.apk';
  const aabPath = 'C:\\Users\\ushma\\.gemini\\antigravity\\brain\\97162d54-0326-4a3b-8680-6508b970e95d\\WrindhaOS-v1.1.1-build36.aab';

  // Upload APK
  if (fs.existsSync(apkPath)) {
    console.log(`⏳ Uploading APK (${(fs.statSync(apkPath).size / 1024 / 1024).toFixed(2)} MB)...`);
    const apkBuffer = fs.readFileSync(apkPath);
    const { data, error } = await supabase.storage
      .from('apks')
      .upload('WrindhaOS-v1.1.1-build36.apk', apkBuffer, {
        contentType: 'application/vnd.android.package-archive',
        upsert: true,
      });

    if (error) {
      console.error('❌ APK Upload Error:', error.message);
    } else {
      console.log('✅ APK Build 36 Uploaded Successfully!');
      const { data: publicUrlData } = supabase.storage.from('apks').getPublicUrl('WrindhaOS-v1.1.1-build36.apk');
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
      .upload('WrindhaOS-v1.1.1-build36.aab', aabBuffer, {
        contentType: 'application/octet-stream',
        upsert: true,
      });

    if (error) {
      console.error('❌ AAB Upload Error:', error.message);
    } else {
      console.log('✅ AAB Build 36 Uploaded Successfully!');
      const { data: publicUrlData } = supabase.storage.from('apks').getPublicUrl('WrindhaOS-v1.1.1-build36.aab');
      console.log('🔗 AAB Public URL:', publicUrlData.publicUrl);
    }
  } else {
    console.error('❌ AAB File not found at:', aabPath);
  }

  console.log('\n==================================================');
  console.log(' UPLOAD COMPLETE');
  console.log('==================================================');
  process.exit(0);
}

uploadBinaries();
