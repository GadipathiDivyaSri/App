const express = require('express');
const router = express.Router();
const expenseController = require('../controllers/expenseController');
const { authenticateUser } = require('../middleware/authMiddleware');

router.use(authenticateUser);

router.get('/', expenseController.getExpenses);
router.post('/', expenseController.createExpense);
router.get('/summary', expenseController.getSummary);
router.post('/budget', expenseController.updateBudget);
router.patch('/:id', expenseController.updateExpense);
router.delete('/:id', expenseController.deleteExpense);

module.exports = router;
