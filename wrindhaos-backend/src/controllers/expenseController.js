const expenseService = require('../services/expenseService');
const { sendSuccess } = require('../utils/response');

async function getExpenses(req, res, next) {
  try {
    const expenses = await expenseService.getExpenses(req.user.id);
    const summary = await expenseService.getExpenseSummary(req.user.id);
    sendSuccess(res, { expenses, summary }, 'Expenses retrieved.');
  } catch (err) {
    next(err);
  }
}

async function createExpense(req, res, next) {
  try {
    const expense = await expenseService.createExpense(req.user.id, req.body);
    const summary = await expenseService.getExpenseSummary(req.user.id);
    sendSuccess(res, { expense, summary }, 'Expense created successfully.', 201);
  } catch (err) {
    next(err);
  }
}

async function updateExpense(req, res, next) {
  try {
    const expense = await expenseService.updateExpense(req.user.id, req.params.id, req.body);
    const summary = await expenseService.getExpenseSummary(req.user.id);
    sendSuccess(res, { expense, summary }, 'Expense updated successfully.');
  } catch (err) {
    next(err);
  }
}

async function deleteExpense(req, res, next) {
  try {
    const result = await expenseService.deleteExpense(req.user.id, req.params.id);
    const summary = await expenseService.getExpenseSummary(req.user.id);
    sendSuccess(res, { ...result, summary }, 'Expense deleted successfully.');
  } catch (err) {
    next(err);
  }
}

async function getSummary(req, res, next) {
  try {
    const summary = await expenseService.getExpenseSummary(req.user.id);
    sendSuccess(res, summary, 'Financial summary calculated.');
  } catch (err) {
    next(err);
  }
}

async function updateBudget(req, res, next) {
  try {
    const summary = await expenseService.updateMonthlyBudget(req.user.id, req.body.amount);
    sendSuccess(res, summary, 'Monthly budget updated.');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getExpenses,
  createExpense,
  updateExpense,
  deleteExpense,
  getSummary,
  updateBudget,
};
