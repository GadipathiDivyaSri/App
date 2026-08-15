const crypto = require('crypto');
const { mockStore } = require('../config/supabase');
const { sendSuccess, sendError } = require('../utils/response');

async function getUserSubjectCount(userId) {
  const userSubjects = Array.from(mockStore.subjects.values()).filter((s) => s.user_id === userId);
  return userSubjects.length;
}

async function getSubjects(req, res, next) {
  try {
    const userSubjects = Array.from(mockStore.subjects.values()).filter((s) => s.user_id === req.user.id);
    sendSuccess(res, { subjects: userSubjects, count: userSubjects.length }, 'Subjects retrieved.');
  } catch (err) {
    next(err);
  }
}

async function createSubject(req, res, next) {
  try {
    const { title, code } = req.body;
    const subjectId = crypto.randomUUID();
    const newSubject = {
      id: subjectId,
      user_id: req.user.id,
      title: title || 'New Subject',
      code: code || 'SUB101',
      mastery_percentage: 0,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    mockStore.subjects.set(subjectId, newSubject);
    sendSuccess(res, { subject: newSubject }, 'Subject created.', 201);
  } catch (err) {
    next(err);
  }
}

async function getSubjectById(req, res, next) {
  try {
    const subject = mockStore.subjects.get(req.params.id);
    if (!subject || subject.user_id !== req.user.id) {
      return sendError(res, 'Subject not found or access denied.', 'NOT_FOUND', 404);
    }
    sendSuccess(res, { subject });
  } catch (err) {
    next(err);
  }
}

async function updateSubject(req, res, next) {
  try {
    const subject = mockStore.subjects.get(req.params.id);
    if (!subject || subject.user_id !== req.user.id) {
      return sendError(res, 'Subject not found or access denied.', 'NOT_FOUND', 404);
    }

    if (req.body.title !== undefined) subject.title = req.body.title;
    if (req.body.mastery_percentage !== undefined) subject.mastery_percentage = req.body.mastery_percentage;
    subject.updated_at = new Date().toISOString();

    mockStore.subjects.set(req.params.id, subject);
    sendSuccess(res, { subject }, 'Subject updated.');
  } catch (err) {
    next(err);
  }
}

async function deleteSubject(req, res, next) {
  try {
    const subject = mockStore.subjects.get(req.params.id);
    if (!subject || subject.user_id !== req.user.id) {
      return sendError(res, 'Subject not found or access denied.', 'NOT_FOUND', 404);
    }

    mockStore.subjects.delete(req.params.id);
    sendSuccess(res, { id: req.params.id }, 'Subject deleted.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getUserSubjectCount,
  getSubjects,
  createSubject,
  getSubjectById,
  updateSubject,
  deleteSubject,
};
