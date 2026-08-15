const crypto = require('crypto');
const { mockStore } = require('../config/supabase');
const { sendSuccess, sendError } = require('../utils/response');

async function getEvents(req, res, next) {
  try {
    let events = Array.from(mockStore.calendarEvents.values()).filter((e) => e.user_id === req.user.id);
    
    // Optional Date-Range Filtering
    const { start, end } = req.query;
    if (start && end) {
      const startDate = new Date(start);
      const endDate = new Date(end);
      events = events.filter((e) => {
        const eStart = new Date(e.start_time);
        return eStart >= startDate && eStart <= endDate;
      });
    }

    sendSuccess(res, { events, count: events.length }, 'Calendar events retrieved.');
  } catch (err) {
    next(err);
  }
}

async function createEvent(req, res, next) {
  try {
    const { title, description, start_time, end_time, location, reminder } = req.body;
    const eventId = crypto.randomUUID();
    const newEvent = {
      id: eventId,
      user_id: req.user.id,
      title: title || 'Calendar Event',
      description: description || '',
      start_time: start_time || new Date().toISOString(),
      end_time: end_time || new Date(Date.now() + 3600000).toISOString(),
      location: location || '',
      reminder: reminder ?? true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    mockStore.calendarEvents.set(eventId, newEvent);
    sendSuccess(res, { event: newEvent }, 'Calendar event created.', 201);
  } catch (err) {
    next(err);
  }
}

async function getEventById(req, res, next) {
  try {
    const event = mockStore.calendarEvents.get(req.params.id);
    if (!event || event.user_id !== req.user.id) {
      return sendError(res, 'Calendar event not found or access denied.', 'NOT_FOUND', 404);
    }
    sendSuccess(res, { event });
  } catch (err) {
    next(err);
  }
}

async function updateEvent(req, res, next) {
  try {
    const event = mockStore.calendarEvents.get(req.params.id);
    if (!event || event.user_id !== req.user.id) {
      return sendError(res, 'Calendar event not found or access denied.', 'NOT_FOUND', 404);
    }

    if (req.body.title !== undefined) event.title = req.body.title;
    if (req.body.description !== undefined) event.description = req.body.description;
    if (req.body.start_time !== undefined) event.start_time = req.body.start_time;
    if (req.body.end_time !== undefined) event.end_time = req.body.end_time;
    event.updated_at = new Date().toISOString();

    mockStore.calendarEvents.set(req.params.id, event);
    sendSuccess(res, { event }, 'Calendar event updated.');
  } catch (err) {
    next(err);
  }
}

async function deleteEvent(req, res, next) {
  try {
    const event = mockStore.calendarEvents.get(req.params.id);
    if (!event || event.user_id !== req.user.id) {
      return sendError(res, 'Calendar event not found or access denied.', 'NOT_FOUND', 404);
    }

    mockStore.calendarEvents.delete(req.params.id);
    sendSuccess(res, { id: req.params.id }, 'Calendar event deleted.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getEvents,
  createEvent,
  getEventById,
  updateEvent,
  deleteEvent,
};
