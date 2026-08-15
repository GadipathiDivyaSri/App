const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateUser } = require('../middleware/authMiddleware');

router.use(authenticateUser);

router.get('/me', userController.getCurrentUser);
router.patch('/me', userController.updateProfile);
router.delete('/me', userController.deleteAccount);

module.exports = router;
