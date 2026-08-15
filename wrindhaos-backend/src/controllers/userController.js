const userService = require('../services/userService');
const { sendSuccess } = require('../utils/response');

async function getCurrentUser(req, res, next) {
  try {
    const user = await userService.getUserById(req.user.id);
    sendSuccess(res, { user }, 'User profile retrieved.');
  } catch (err) {
    next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const user = await userService.updateUserProfile(req.user.id, req.body);
    sendSuccess(res, { user }, 'User profile updated.');
  } catch (err) {
    next(err);
  }
}

async function deleteAccount(req, res, next) {
  try {
    const result = await userService.deleteUserAccount(req.user.id, req.ip);
    sendSuccess(res, result, 'User account deleted.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getCurrentUser,
  updateProfile,
  deleteAccount,
};
