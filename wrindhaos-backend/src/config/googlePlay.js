const { google } = require('googleapis');
const config = require('./env');

let androidPublisher = null;

try {
  if (config.googlePlay.serviceAccountEmail && config.googlePlay.privateKey) {
    const auth = new google.auth.JWT(
      config.googlePlay.serviceAccountEmail,
      null,
      config.googlePlay.privateKey,
      ['https://www.googleapis.com/auth/androidpublisher']
    );
    androidPublisher = google.androidpublisher({ version: 'v3', auth });
    console.log('[GOOGLE PLAY] AndroidPublisher API client initialized successfully.');
  }
} catch (err) {
  console.warn('[GOOGLE PLAY] Google Play Service Account not configured or invalid. Operating in mock verification mode.');
}

module.exports = {
  androidPublisher,
};
