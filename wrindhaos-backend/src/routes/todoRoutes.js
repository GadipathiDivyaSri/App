const express = require('express');
const router = express.Router();
const todoController = require('../controllers/todoController');
const { authenticateUser } = require('../middleware/authMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');

router.use(authenticateUser);

router.get('/', todoController.getTodos);
router.post('/', validateBody(['title']), todoController.createTodo);
router.get('/:id', todoController.getTodoById);
router.patch('/:id', todoController.updateTodo);
router.delete('/:id', todoController.deleteTodo);

module.exports = router;
