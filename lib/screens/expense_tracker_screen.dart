import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'add_expense_screen.dart';

class ExpenseTrackerScreen extends StatelessWidget {
  const ExpenseTrackerScreen({super.key});

  void _showEditBudgetDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController(
      text: provider.monthlyBudget.toStringAsFixed(0),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Monthly Budget',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monthly Budget Amount (₹)',
              border: OutlineInputBorder(),
              prefixText: '₹ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final newAmount = double.tryParse(controller.text.trim());
                if (newAmount != null && newAmount > 0) {
                  provider.editMonthlyBudget(newAmount);
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive budget amount.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditExpenseDialog(BuildContext context, AppProvider provider, ExpenseTransaction expense) {
    final titleCtrl = TextEditingController(text: expense.title);
    final amountCtrl = TextEditingController(text: expense.amount.toStringAsFixed(2));
    String category = expense.category;
    bool isIncome = expense.isIncome;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Transaction',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () {
                          provider.deleteExpense(expense.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense deleted and balance updated.')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title / Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ['Food & Drinks', 'Shopping', 'Transport', 'Education', 'Entertainment', 'Income', 'General'].contains(category)
                        ? category
                        : 'General',
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Food & Drinks', child: Text('Food & Drinks')),
                      DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                      DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                      DropdownMenuItem(value: 'Education', child: Text('Education')),
                      DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
                      DropdownMenuItem(value: 'Income', child: Text('Income')),
                      DropdownMenuItem(value: 'General', child: Text('General')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          category = val;
                          isIncome = val == 'Income';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D5CE5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final parsed = double.tryParse(amountCtrl.text.trim());
                        if (parsed == null || parsed <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount greater than 0.')),
                          );
                          return;
                        }
                        provider.editExpense(
                          expense.id,
                          titleCtrl.text.trim(),
                          category,
                          parsed,
                          isIncome: isIncome,
                          paymentMethod: expense.paymentMethod,
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);

    final budget = provider.monthlyBudget;
    final totalSpent = provider.totalExpenses;
    final totalIncome = provider.totalIncome;
    final availableBalance = provider.availableBalance;
    final progress = budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;
    final expenses = provider.expenses;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Expense Tracker',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_fab',
        backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddExpenseScreen(),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available Balance & Monthly Budget Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(22),
                border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
                boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'AVAILABLE BALANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showEditBudgetDialog(context, provider),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: isDark ? AppTheme.darkIconGlow : AppTheme.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${availableBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: availableBalance >= 0
                          ? (isDark ? Colors.white : AppTheme.textPrimary)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark ? const Color(0xFF132F5C) : const Color(0xFFFFF0E8),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 0.9 ? const Color(0xFFEF4444) : (isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spent: ₹${totalSpent.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                        ),
                      ),
                      if (totalIncome > 0)
                        Text(
                          'Income: +₹${totalIncome.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      Text(
                        'Budget: ₹${budget.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkIconGlow : AppTheme.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Expenses Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions (${expenses.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Tap to Edit / Delete',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Expense Items List
            if (expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'No transactions recorded yet.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap the + button below to log your first expense.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return _buildExpenseCard(context, provider, expense);
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, AppProvider provider, ExpenseTransaction expense) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = expense.isIncome;
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(expense.date);

    IconData icon = Icons.shopping_bag_outlined;
    if (isIncome) {
      icon = Icons.account_balance_wallet_outlined;
    } else if (expense.category.contains('Food')) {
      icon = Icons.restaurant_outlined;
    } else if (expense.category.contains('Transport')) {
      icon = Icons.directions_car_outlined;
    } else if (expense.category.contains('Education')) {
      icon = Icons.school_outlined;
    }

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        provider.deleteExpense(expense.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted and balance restored.')),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      child: InkWell(
        onTap: () => _showEditExpenseDialog(context, provider, expense),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isIncome ? const Color(0xFF10B981) : const Color(0xFF0D5CE5)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isIncome ? const Color(0xFF10B981) : const Color(0xFF0D5CE5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expense.category}  •  $dateStr',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'} ₹${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
