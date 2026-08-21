const crypto = require('crypto');
const { mockStore } = require('../config/supabase');

/**
 * Get all expenses for authenticated user
 */
async function getExpenses(userId) {
  const userExpenses = Array.from(mockStore.expenses.values())
    .filter((e) => e.user_id === userId)
    .sort((a, b) => new Date(b.date || b.created_at) - new Date(a.date || a.created_at));

  return userExpenses;
}

/**
 * Create a new expense or income transaction
 */
async function createExpense(userId, data) {
  const { title, category, amount, isIncome, is_income, paymentMethod, payment_method, date } = data;

  const parsedAmount = typeof amount === 'number' ? amount : parseFloat(amount);
  if (isNaN(parsedAmount) || parsedAmount <= 0) {
    throw { statusCode: 400, code: 'INVALID_AMOUNT', message: 'Expense amount must be a positive number greater than 0.' };
  }

  const isInc = isIncome ?? is_income ?? false;
  const expenseId = crypto.randomUUID();
  const newExpense = {
    id: expenseId,
    user_id: userId,
    title: (title && title.trim().length > 0) ? title.trim() : (category || 'Expense'),
    category: category || (isInc ? 'Income' : 'General'),
    amount: parsedAmount,
    is_income: isInc,
    payment_method: paymentMethod || payment_method || 'UPI',
    date: date ? new Date(date).toISOString() : new Date().toISOString(),
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  mockStore.expenses.set(expenseId, newExpense);
  return newExpense;
}

/**
 * Update an existing expense transaction
 */
async function updateExpense(userId, expenseId, data) {
  const expense = mockStore.expenses.get(expenseId);
  if (!expense || expense.user_id !== userId) {
    throw { statusCode: 404, code: 'EXPENSE_NOT_FOUND', message: 'Expense transaction not found or access denied.' };
  }

  if (data.amount !== undefined) {
    const parsedAmount = typeof data.amount === 'number' ? data.amount : parseFloat(data.amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      throw { statusCode: 400, code: 'INVALID_AMOUNT', message: 'Expense amount must be greater than 0.' };
    }
    expense.amount = parsedAmount;
  }

  if (data.title !== undefined) expense.title = data.title.trim() || expense.title;
  if (data.category !== undefined) expense.category = data.category;
  if (data.isIncome !== undefined || data.is_income !== undefined) {
    expense.is_income = data.isIncome ?? data.is_income;
  }
  if (data.paymentMethod !== undefined || data.payment_method !== undefined) {
    expense.payment_method = data.paymentMethod ?? data.payment_method;
  }
  if (data.date !== undefined) expense.date = new Date(data.date).toISOString();
  expense.updated_at = new Date().toISOString();

  mockStore.expenses.set(expenseId, expense);
  return expense;
}

/**
 * Delete an expense transaction
 */
async function deleteExpense(userId, expenseId) {
  const expense = mockStore.expenses.get(expenseId);
  if (!expense || expense.user_id !== userId) {
    throw { statusCode: 404, code: 'EXPENSE_NOT_FOUND', message: 'Expense transaction not found or access denied.' };
  }

  mockStore.expenses.delete(expenseId);
  return { success: true, id: expenseId, message: 'Expense transaction deleted and balance recalculated.' };
}

/**
 * Get user financial health summary
 * available_balance = opening_balance + income - total_expenses
 */
async function getExpenseSummary(userId) {
  const budget = mockStore.monthlyBudgets.get(userId) || 10000.0;
  const userExpenses = Array.from(mockStore.expenses.values()).filter((e) => e.user_id === userId);

  let totalExpenses = 0.0;
  let totalIncome = 0.0;

  for (const exp of userExpenses) {
    if (exp.is_income === true) {
      totalIncome += Number(exp.amount);
    } else {
      totalExpenses += Number(exp.amount);
    }
  }

  const availableBalance = budget + totalIncome - totalExpenses;

  return {
    monthlyBudget: budget,
    openingBalance: budget,
    totalExpenses: Math.round(totalExpenses * 100) / 100,
    totalIncome: Math.round(totalIncome * 100) / 100,
    availableBalance: Math.round(availableBalance * 100) / 100,
    transactionCount: userExpenses.length,
  };
}

/**
 * Update monthly budget amount
 */
async function updateMonthlyBudget(userId, amount) {
  const parsedAmount = typeof amount === 'number' ? amount : parseFloat(amount);
  if (isNaN(parsedAmount) || parsedAmount <= 0) {
    throw { statusCode: 400, code: 'INVALID_BUDGET', message: 'Monthly budget must be a positive number greater than 0.' };
  }

  mockStore.monthlyBudgets.set(userId, parsedAmount);
  return getExpenseSummary(userId);
}

module.exports = {
  getExpenses,
  createExpense,
  updateExpense,
  deleteExpense,
  getExpenseSummary,
  updateMonthlyBudget,
};
