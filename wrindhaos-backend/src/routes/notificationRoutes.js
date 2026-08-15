const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticateUser } = require('../middleware/authMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');

router.use(authenticateUser);

router.post('/register-device', validateBody(['token']), notificationController.registerDevice);
router.delete('/unregister-device', validateBody(['token']), notificationController.unregisterDevice);
router.post('/trigger-alert', validateBody(['title', 'body']), notificationController.triggerPushAlert);

module.exports = router;
