const express = require('express');
const router = express.Router();
const eisenhowerController = require('../controllers/eisenhowerController');
const { authenticateUser } = require('../middleware/authMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');

router.use(authenticateUser);

router.get('/', eisenhowerController.getEisenhowerTasks);
router.post('/', validateBody(['title', 'quadrant']), eisenhowerController.createEisenhowerTask);
router.patch('/:id', eisenhowerController.updateEisenhowerTask);
router.delete('/:id', eisenhowerController.deleteEisenhowerTask);

module.exports = router;
