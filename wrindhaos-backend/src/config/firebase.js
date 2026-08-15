const admin = require('firebase-admin');
const config = require('./env');

let messaging = null;

try {
  if (config.fcm.clientEmail && config.fcm.privateKey && !admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: config.fcm.projectId,
        clientEmail: config.fcm.clientEmail,
        privateKey: config.fcm.privateKey,
      }),
    });
    messaging = admin.messaging();
    console.log('[FIREBASE FCM] Firebase Admin SDK initialized successfully.');
  }
} catch (err) {
  console.warn('[FIREBASE FCM] Firebase credentials not configured. Operating in mock notification mode.');
}

module.exports = {
  admin,
  messaging,
};
