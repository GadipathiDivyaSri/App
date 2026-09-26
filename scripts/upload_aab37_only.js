const fs = require('fs');
const { supabase } = require('../backend/supabase_client');

async function uploadAAB() {
  const aabPath = 'C:\\Users\\ushma\\.gemini\\antigravity\\brain\\97162d54-0326-4a3b-8680-6508b970e95d\\WrindhaOS-v1.1.1-build37.aab';
  console.log(`⏳ Uploading AAB (${(fs.statSync(aabPath).size / 1024 / 1024).toFixed(2)} MB)...`);
  const aabBuffer = fs.readFileSync(aabPath);

  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      console.log(`Attempt ${attempt}...`);
      const { data, error } = await supabase.storage
        .from('apks')
        .upload('WrindhaOS-v1.1.1-build37.aab', aabBuffer, {
          contentType: 'application/octet-stream',
          upsert: true,
        });

      if (error) {
        console.error(`Attempt ${attempt} error:`, error.message);
      } else {
        console.log('✅ AAB Build 37 Uploaded Successfully!');
        const { data: publicUrlData } = supabase.storage.from('apks').getPublicUrl('WrindhaOS-v1.1.1-build37.aab');
        console.log('🔗 AAB Public URL:', publicUrlData.publicUrl);
        process.exit(0);
      }
    } catch (e) {
      console.error(`Attempt ${attempt} exception:`, e.message);
    }
  }
  process.exit(1);
}

uploadAAB();
