const notificationService = require('../services/notificationService');
const { sendSuccess } = require('../utils/response');

async function registerDevice(req, res, next) {
  try {
    const { token, platform, deviceId } = req.body;
    const result = await notificationService.registerDeviceToken(req.user.id, token, platform, deviceId);
    sendSuccess(res, result, 'FCM device token registered.');
  } catch (err) {
    next(err);
  }
}

async function unregisterDevice(req, res, next) {
  try {
    const { token } = req.body;
    const result = await notificationService.unregisterDeviceToken(req.user.id, token);
    sendSuccess(res, result, 'FCM device token unregistered.');
  } catch (err) {
    next(err);
  }
}

async function triggerPushAlert(req, res, next) {
  try {
    const { title, body, data } = req.body;
    const result = await notificationService.sendPushNotification(req.user.id, title, body, data);
    sendSuccess(res, result, 'FCM push notification triggered.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  registerDevice,
  unregisterDevice,
  triggerPushAlert,
};
