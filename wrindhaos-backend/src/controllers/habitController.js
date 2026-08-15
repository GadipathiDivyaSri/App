const crypto = require('crypto');
const { mockStore } = require('../config/supabase');
const { sendSuccess, sendError } = require('../utils/response');

async function getUserHabitCount(userId) {
  const userHabits = Array.from(mockStore.habits.values()).filter((h) => h.user_id === userId);
  return userHabits.length;
}

async function getHabits(req, res, next) {
  try {
    const userHabits = Array.from(mockStore.habits.values()).filter((h) => h.user_id === req.user.id);
    sendSuccess(res, { habits: userHabits, count: userHabits.length }, 'Habits retrieved.');
  } catch (err) {
    next(err);
  }
}

async function createHabit(req, res, next) {
  try {
    const { title, frequency, target_days } = req.body;
    const habitId = crypto.randomUUID();
    const newHabit = {
      id: habitId,
      user_id: req.user.id,
      title: title || 'Daily Habit',
      frequency: frequency || 'Daily',
      target_days: target_days || 7,
      current_streak: 1,
      is_completed_today: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    mockStore.habits.set(habitId, newHabit);
    sendSuccess(res, { habit: newHabit }, 'Habit created.', 201);
  } catch (err) {
    next(err);
  }
}

async function getHabitById(req, res, next) {
  try {
    const habit = mockStore.habits.get(req.params.id);
    if (!habit || habit.user_id !== req.user.id) {
      return sendError(res, 'Habit not found or access denied.', 'NOT_FOUND', 404);
    }
    sendSuccess(res, { habit });
  } catch (err) {
    next(err);
  }
}

async function updateHabit(req, res, next) {
  try {
    const habit = mockStore.habits.get(req.params.id);
    if (!habit || habit.user_id !== req.user.id) {
      return sendError(res, 'Habit not found or access denied.', 'NOT_FOUND', 404);
    }

    if (req.body.title !== undefined) habit.title = req.body.title;
    if (req.body.is_completed_today !== undefined) {
      habit.is_completed_today = req.body.is_completed_today;
      if (req.body.is_completed_today) habit.current_streak += 1;
    }
    habit.updated_at = new Date().toISOString();

    mockStore.habits.set(req.params.id, habit);
    sendSuccess(res, { habit }, 'Habit updated.');
  } catch (err) {
    next(err);
  }
}

async function deleteHabit(req, res, next) {
  try {
    const habit = mockStore.habits.get(req.params.id);
    if (!habit || habit.user_id !== req.user.id) {
      return sendError(res, 'Habit not found or access denied.', 'NOT_FOUND', 404);
    }

    mockStore.habits.delete(req.params.id);
    sendSuccess(res, { id: req.params.id }, 'Habit deleted.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getUserHabitCount,
  getHabits,
  createHabit,
  getHabitById,
  updateHabit,
  deleteHabit,
};
