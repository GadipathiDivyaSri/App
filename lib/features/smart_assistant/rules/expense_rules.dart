import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class ExpenseRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    switch (intent) {
      case SmartIntent.addExpense:
        return _addExpense(entities, provider);
      case SmartIntent.deleteExpense:
        return _deleteExpense(entities, provider);
      case SmartIntent.expenseSummary:
        return _getExpenseSummary(provider);
      case SmartIntent.getExpenses:
      default:
        return _getAllExpenses(provider);
    }
  }

  static AssistantMessage _addExpense(ExtractedEntities entities, AppProvider provider) {
    final amount = entities.amount ?? 0.0;
    if (amount <= 0) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'How much did you spend? For example: *"I spent ₹250 on lunch"*.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['I spent ₹250 on food', 'Add 500 rupees for transport'],
      );
    }

    final category = entities.category ?? 'Food & Dining';
    final title = entities.title ?? category;

    provider.addExpense(title, category, amount);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '💸 Logged expense: **₹${amount.toStringAsFixed(0)}** for **$title** ($category).',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.addExpense,
      cardData: ActionCardData(
        type: ActionCardType.expenseSummary,
        title: '₹${amount.toStringAsFixed(0)}',
        subtitle: '$title • $category',
        items: [
          ActionCardItem(
            id: 'exp_logged',
            title: title,
            subtitle: category,
            trailingText: '₹${amount.toStringAsFixed(0)}',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFFEF4444),
          ),
        ],
      ),
      suggestionChips: ['How much did I spend this month?', 'Show my expenses'],
    );
  }

  static AssistantMessage _deleteExpense(ExtractedEntities entities, AppProvider provider) {
    final expenses = provider.expenses;
    if (expenses.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You have no expense transactions to delete.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    final target = expenses.first;
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '⚠️ Are you sure you want to delete the expense **"${target.title}" (₹${target.amount.toStringAsFixed(0)})**?',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.deleteExpense,
      cardData: ActionCardData(
        type: ActionCardType.confirmationPrompt,
        title: 'Delete Expense',
        subtitle: '${target.title} • ₹${target.amount.toStringAsFixed(0)}',
        actions: [
          ActionButton(
            label: 'Confirm Delete',
            isDestructive: true,
            commandPayload: 'CONFIRM_DELETE_EXPENSE_${target.id}',
          ),
          ActionButton(
            label: 'Cancel',
            isPrimary: false,
            commandPayload: 'CANCEL_ACTION',
          ),
        ],
      ),
    );
  }

  static AssistantMessage _getExpenseSummary(AppProvider provider) {
    final totalSpent = provider.totalExpenses;
    final budget = provider.monthlyBudget;
    final remaining = budget - totalSpent;
    final percentage = budget > 0 ? (totalSpent / budget * 100).clamp(0, 100).toStringAsFixed(1) : '0';

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📊 **Monthly Financial Summary**:\n• Total Spent: **₹${totalSpent.toStringAsFixed(0)}**\n• Monthly Budget: **₹${budget.toStringAsFixed(0)}**\n• Remaining Balance: **₹${remaining.toStringAsFixed(0)}** ($percentage% used)',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.expenseSummary,
      cardData: ActionCardData(
        type: ActionCardType.expenseSummary,
        title: '₹${totalSpent.toStringAsFixed(0)} Spent',
        subtitle: '₹${remaining.toStringAsFixed(0)} remaining of ₹${budget.toStringAsFixed(0)} budget',
        items: [
          ActionCardItem(
            id: 'budget_1',
            title: 'Budget Utilization',
            subtitle: '$percentage% of monthly budget consumed',
            icon: Icons.pie_chart_outline_rounded,
            iconColor: const Color(0xFF0D5CE5),
          ),
        ],
      ),
      suggestionChips: ['Show my expenses', 'I spent ₹150 on coffee'],
    );
  }

  static AssistantMessage _getAllExpenses(AppProvider provider) {
    final expenses = provider.expenses;

    if (expenses.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You haven\'t logged any expenses yet. Tell me what you spent to start tracking!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['I spent ₹250 on food', 'Add ₹500 for transport'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '💳 Here are your recent expense transactions (Total: **₹${provider.totalExpenses.toStringAsFixed(0)}**):',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getExpenses,
      cardData: ActionCardData(
        type: ActionCardType.expenseSummary,
        title: 'Recent Expenses',
        subtitle: '${expenses.length} transactions logged',
        items: expenses.take(5).map((e) => ActionCardItem(
          id: e.id,
          title: e.title,
          subtitle: '${e.category} • ${e.date.day}/${e.date.month}',
          trailingText: '₹${e.amount.toStringAsFixed(0)}',
          icon: e.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          iconColor: e.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        )).toList(),
      ),
      suggestionChips: ['How much did I spend this month?', 'I spent ₹100 on snacks'],
    );
  }
}
