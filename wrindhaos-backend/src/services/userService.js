const { mockStore } = require('../config/supabase');
const { logAuditEvent } = require('../utils/auditLogger');
const AUDIT_EVENTS = require('../constants/auditEvents');

async function getUserById(userId) {
  const user = mockStore.users.get(userId);
  if (!user) {
    throw { statusCode: 404, code: 'USER_NOT_FOUND', message: 'User profile not found.' };
  }
  return user;
}

async function updateUserProfile(userId, updates) {
  const user = await getUserById(userId);

  if (updates.full_name !== undefined) user.full_name = updates.full_name;
  if (updates.profile_image !== undefined) user.profile_image = updates.profile_image;
  user.updated_at = new Date().toISOString();

  mockStore.users.set(userId, user);
  return user;
}

async function deleteUserAccount(userId, ipAddress) {
  const user = await getUserById(userId);

  // Clean up user-owned data
  mockStore.users.delete(userId);

  for (const [key, val] of mockStore.todos.entries()) {
    if (val.user_id === userId) mockStore.todos.delete(key);
  }
  for (const [key, val] of mockStore.habits.entries()) {
    if (val.user_id === userId) mockStore.habits.delete(key);
  }
  for (const [key, val] of mockStore.subjects.entries()) {
    if (val.user_id === userId) mockStore.subjects.delete(key);
  }

  await logAuditEvent(userId, AUDIT_EVENTS.ACCOUNT_DELETED, {}, ipAddress);
  return { success: true, message: 'User account and associated data successfully deleted.' };
}

module.exports = {
  getUserById,
  updateUserProfile,
  deleteUserAccount,
};
