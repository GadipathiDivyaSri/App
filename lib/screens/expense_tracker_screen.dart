import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'add_expense_screen.dart';

/// Expense Tracker Screen for WrindhaOS
/// 
/// Features:
/// - Filter by: [ Week ] and [ Month ]
/// - Period Navigation: < Previous    Current    Next >
/// - Category breakdown and total calculations for selected period
/// - Reusable PremiumLockBanner in preview state for Free users
class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  void _showEditBudgetDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController(
      text: provider.monthlyBudget.toStringAsFixed(0),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

  void _goToPreviousPeriod() {
    setState(() {
      if (_selectedView == 'MONTH') {
        _currentPeriodDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month - 1, 1);
      } else {
        _currentPeriodDate = _currentPeriodDate.subtract(const Duration(days: 7));
      }
    });
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
    final isPremium = provider.user.isPremium;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;

    final filteredExpenses = _filterExpensesForPeriod(provider.expenses);
    final totalSpent = filteredExpenses.where((e) => !e.isIncome).fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = filteredExpenses.where((e) => e.isIncome).fold(0.0, (sum, e) => sum + e.amount);

    // Group expenses by category
    final Map<String, double> categoryBreakdown = {};
    for (var exp in filteredExpenses.where((e) => !e.isIncome)) {
      categoryBreakdown[exp.category] = (categoryBreakdown[exp.category] ?? 0.0) + exp.amount;
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Expense Tracker',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: primaryColor, size: 28),
            onPressed: () {
              if (!isPremium) {
                showUpgradeProModal(
                  context,
                  featureTitle: 'Expense Tracker',
                  limitExplanation: 'Free plan gives you a preview of Expense Tracker. Upgrade to Pro for ₹49/month to add and track your finances!',
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              }
            },
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Available Balance & Monthly Budget Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: textPrimary),
                    onPressed: _goToPreviousPeriod,
                  ),
                  GestureDetector(
                    onTap: _resetToCurrent,
                    child: Column(
                      children: [
                        Text(
                          _getPeriodLabel(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to return to today',
                          style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: textPrimary),
                    onPressed: _goToNextPeriod,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4. Period Spending Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppTheme.darkCardBorder : const Color(0xFFFDE68A),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    '${_selectedView == 'MONTH' ? 'Monthly' : 'Weekly'} Total Spending',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${totalSpent.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Income: +₹${totalIncome.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${filteredExpenses.length} transactions',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Category Breakdown Section
            Text(
              'Category Breakdown',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 12),

            if (categoryBreakdown.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                ),
                child: Center(
                  child: Text('No expenses recorded for this period.', style: TextStyle(color: textSecondary)),
                ),
              )
            else
              Column(
                children: categoryBreakdown.entries.map((entry) {
                  final percent = totalSpent > 0 ? (entry.value / totalSpent) : 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                            Text('₹${entry.value.toStringAsFixed(2)} (${(percent * 100).round()}%)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 6,
                            backgroundColor: isDark ? Colors.white10 : Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // 6. Transactions List for Selected Period
            Text(
              'Transactions',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 12),

            if (filteredExpenses.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                ),
                child: Center(
                  child: Text('No transactions in this period.', style: TextStyle(color: textSecondary)),
                ),
              )
            else
              Column(
                children: filteredExpenses.map((exp) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: exp.isIncome
                                ? const Color(0xFF10B981).withOpacity(0.15)
                                : Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            exp.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: exp.isIncome ? const Color(0xFF10B981) : Colors.redAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exp.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                              const SizedBox(height: 2),
                              Text('${exp.category} • ${DateFormat('MMM d').format(exp.date)}', style: TextStyle(fontSize: 12, color: textSecondary)),
                            ],
                          ),
                        ),
                        Text(
                          '${exp.isIncome ? '+' : '-'}₹${exp.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: exp.isIncome ? const Color(0xFF10B981) : textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
