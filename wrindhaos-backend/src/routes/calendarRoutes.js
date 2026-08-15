const express = require('express');
const router = express.Router();
const calendarController = require('../controllers/calendarController');
const { authenticateUser } = require('../middleware/authMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');

router.use(authenticateUser);

router.get('/events', calendarController.getEvents);
router.post('/events', validateBody(['title']), calendarController.createEvent);
router.get('/events/:id', calendarController.getEventById);
router.patch('/events/:id', calendarController.updateEvent);
router.delete('/events/:id', calendarController.deleteEvent);

module.exports = router;
