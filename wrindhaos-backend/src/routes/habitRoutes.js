const express = require('express');
const router = express.Router();
const habitController = require('../controllers/habitController');
const { authenticateUser } = require('../middleware/authMiddleware');
const { enforceFeatureLimit } = require('../middleware/premiumMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');
const { FEATURES } = require('../constants/entitlements');

router.use(authenticateUser);

router.get('/', habitController.getHabits);
router.post(
  '/',
  validateBody(['title']),
  enforceFeatureLimit(FEATURES.HABITS, habitController.getUserHabitCount, 'HABIT_LIMIT_REACHED'),
  habitController.createHabit
);
router.get('/:id', habitController.getHabitById);
router.patch('/:id', habitController.updateHabit);
router.delete('/:id', habitController.deleteHabit);

module.exports = router;
