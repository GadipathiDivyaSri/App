const crypto = require('crypto');
const { mockStore } = require('../config/supabase');
const { sendSuccess, sendError } = require('../utils/response');

async function getEisenhowerTasks(req, res, next) {
  try {
    const tasks = Array.from(mockStore.eisenhowerTasks.values()).filter((t) => t.user_id === req.user.id);
    sendSuccess(res, { tasks, count: tasks.length }, 'Eisenhower priority tasks retrieved.');
  } catch (err) {
    next(err);
  }
}

async function createEisenhowerTask(req, res, next) {
  try {
    const { title, quadrant } = req.body;
    const taskId = crypto.randomUUID();
    const newTask = {
      id: taskId,
      user_id: req.user.id,
      title: title || 'Eisenhower Task',
      quadrant: quadrant || 1, // Quadrant 1, 2, 3, 4
      is_completed: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    mockStore.eisenhowerTasks.set(taskId, newTask);
    sendSuccess(res, { task: newTask }, 'Eisenhower priority task created.', 201);
  } catch (err) {
    next(err);
  }
}

async function updateEisenhowerTask(req, res, next) {
  try {
    const task = mockStore.eisenhowerTasks.get(req.params.id);
    if (!task || task.user_id !== req.user.id) {
      return sendError(res, 'Eisenhower task not found or access denied.', 'NOT_FOUND', 404);
    }

    if (req.body.title !== undefined) task.title = req.body.title;
    if (req.body.quadrant !== undefined) task.quadrant = req.body.quadrant;
    if (req.body.is_completed !== undefined) task.is_completed = req.body.is_completed;
    task.updated_at = new Date().toISOString();

    mockStore.eisenhowerTasks.set(req.params.id, task);
    sendSuccess(res, { task }, 'Eisenhower task updated.');
  } catch (err) {
    next(err);
  }
}

async function deleteEisenhowerTask(req, res, next) {
  try {
    const task = mockStore.eisenhowerTasks.get(req.params.id);
    if (!task || task.user_id !== req.user.id) {
      return sendError(res, 'Eisenhower task not found or access denied.', 'NOT_FOUND', 404);
    }

    mockStore.eisenhowerTasks.delete(req.params.id);
    sendSuccess(res, { id: req.params.id }, 'Eisenhower task deleted.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getEisenhowerTasks,
  createEisenhowerTask,
  updateEisenhowerTask,
  deleteEisenhowerTask,
};
