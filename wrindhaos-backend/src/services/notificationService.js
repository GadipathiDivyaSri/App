const crypto = require('crypto');
const { messaging } = require('../config/firebase');
const { mockStore } = require('../config/supabase');
const logger = require('../utils/logger');

async function registerDeviceToken(userId, token, platform = 'flutter_android', deviceId = null) {
  const tokenId = crypto.randomUUID();
  const tokenRecord = {
    id: tokenId,
    user_id: userId,
    token,
    platform,
    device_id: deviceId,
    created_at: new Date().toISOString(),
  };

  mockStore.deviceTokens.set(token, tokenRecord);
  logger.info('Device token registered for FCM notifications', { userId, platform });
  return tokenRecord;
}

async function unregisterDeviceToken(userId, token) {
  mockStore.deviceTokens.delete(token);
  logger.info('Device token unregistered', { userId });
  return { success: true };
}

async function sendPushNotification(userId, title, body, data = {}) {
  logger.info(`[FCM PUSH] Dispatching notification to User ${userId}`, { title, body });

  if (messaging) {
    const userTokens = Array.from(mockStore.deviceTokens.values())
      .filter((t) => t.user_id === userId)
      .map((t) => t.token);

    if (userTokens.length > 0) {
      await messaging.sendMulticast({
        tokens: userTokens,
        notification: { title, body },
        data,
      });
    }
  }

  return { success: true, messageId: `msg_${Date.now()}` };
}

module.exports = {
  registerDeviceToken,
  unregisterDeviceToken,
  sendPushNotification,
};
