const crypto = require('crypto');
const { mockStore } = require('../config/supabase');
const { sendSuccess, sendError } = require('../utils/response');

async function getTodos(req, res, next) {
  try {
    const userTodos = Array.from(mockStore.todos.values()).filter((t) => t.user_id === req.user.id);
    sendSuccess(res, { todos: userTodos }, 'Todos retrieved.');
  } catch (err) {
    next(err);
  }
}

async function createTodo(req, res, next) {
  try {
    const { title, category, priority, due_date, due_date_label } = req.body;

    if (due_date) {
      const parsedDueDate = new Date(due_date);
      const todayMidnight = new Date();
      todayMidnight.setHours(0, 0, 0, 0);

      const dueMidnight = new Date(parsedDueDate);
      dueMidnight.setHours(0, 0, 0, 0);

      if (dueMidnight < todayMidnight) {
        return sendError(
          res,
          'Cannot create tasks scheduled for dates in the past. Only today and future dates are allowed.',
          'PAST_DATE_FORBIDDEN',
          400
        );
      }
    }

    const todoId = crypto.randomUUID();
    const newTodo = {
      id: todoId,
      user_id: req.user.id,
      title: title || 'New Task',
      category: category || 'General',
      priority: priority || 'MEDIUM',
      due_date: due_date || null,
      due_date_label: due_date_label || 'Today',
      is_completed: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    mockStore.todos.set(todoId, newTodo);
    sendSuccess(res, { todo: newTodo }, 'Todo created.', 201);
  } catch (err) {
    next(err);
  }
}

async function getTodoById(req, res, next) {
  try {
    const todo = mockStore.todos.get(req.params.id);
    if (!todo || todo.user_id !== req.user.id) {
      return sendError(res, 'Todo task not found or access denied.', 'NOT_FOUND', 404);
    }
    sendSuccess(res, { todo });
  } catch (err) {
    next(err);
  }
}

async function updateTodo(req, res, next) {
  try {
    const todo = mockStore.todos.get(req.params.id);
    if (!todo || todo.user_id !== req.user.id) {
      return sendError(res, 'Todo task not found or access denied.', 'NOT_FOUND', 404);
    }

    if (req.body.title !== undefined) todo.title = req.body.title;
    if (req.body.is_completed !== undefined) todo.is_completed = req.body.is_completed;
    if (req.body.priority !== undefined) todo.priority = req.body.priority;
    todo.updated_at = new Date().toISOString();

    mockStore.todos.set(req.params.id, todo);
    sendSuccess(res, { todo }, 'Todo updated.');
  } catch (err) {
    next(err);
  }
}

async function deleteTodo(req, res, next) {
  try {
    const todo = mockStore.todos.get(req.params.id);
    if (!todo || todo.user_id !== req.user.id) {
      return sendError(res, 'Todo task not found or access denied.', 'NOT_FOUND', 404);
    }

    mockStore.todos.delete(req.params.id);
    sendSuccess(res, { id: req.params.id }, 'Todo deleted.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getTodos,
  createTodo,
  getTodoById,
  updateTodo,
  deleteTodo,
};
