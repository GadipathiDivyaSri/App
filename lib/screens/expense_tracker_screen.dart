import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/subscription_config.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/pro_feature_guard.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../widgets/premium_lock_banner.dart';
import '../widgets/upgrade_pro_modal.dart';
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

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  // 'WEEK' or 'MONTH'
  String _selectedView = 'MONTH';
  DateTime _currentPeriodDate = DateTime.now();

  void _goToPreviousPeriod() {
    setState(() {
      if (_selectedView == 'MONTH') {
        _currentPeriodDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month - 1, 1);
      } else {
        _currentPeriodDate = _currentPeriodDate.subtract(const Duration(days: 7));
      }
    });
  }

  void _goToNextPeriod() {
    setState(() {
      if (_selectedView == 'MONTH') {
        _currentPeriodDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month + 1, 1);
      } else {
        _currentPeriodDate = _currentPeriodDate.add(const Duration(days: 7));
      }
    });
  }

  void _resetToCurrent() {
    setState(() {
      _currentPeriodDate = DateTime.now();
    });
  }

  String _getPeriodLabel() {
    if (_selectedView == 'MONTH') {
      return DateFormat('MMMM yyyy').format(_currentPeriodDate);
    } else {
      final startOfWeek = _currentPeriodDate.subtract(Duration(days: _currentPeriodDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(startOfWeek)} – ${DateFormat('MMM d').format(endOfWeek)}';
    }
  }

  List<ExpenseTransaction> _filterExpensesForPeriod(List<ExpenseTransaction> all) {
    if (_selectedView == 'MONTH') {
      return all.where((e) {
        return e.date.year == _currentPeriodDate.year && e.date.month == _currentPeriodDate.month;
      }).toList();
    } else {
      final startOfWeek = DateTime(
        _currentPeriodDate.year,
        _currentPeriodDate.month,
        _currentPeriodDate.day - (_currentPeriodDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      return all.where((e) {
        return !e.date.isBefore(startOfWeek) && e.date.isBefore(endOfWeek);
      }).toList();
    }
  }

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

    final Map<String, double> categoryBreakdown = {};
    for (var exp in filteredExpenses.where((e) => !e.isIncome)) {
      categoryBreakdown[exp.category] = (categoryBreakdown[exp.category] ?? 0.0) + exp.amount;
    }

    return ProFeatureGuard(
      feature: AppFeature.expenseTracker,
      child: Scaffold(
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
                  ProUpgradeDialog.showFeatureLockedDialog(context, AppFeature.expenseTracker);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                  );
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // 1. Premium Lock Banner if Free
            if (!isPremium)
              const PremiumLockBanner(
                featureName: 'Expense Tracker',
                description: 'You are currently viewing Expense Tracker in preview mode. Upgrade to Pro for ₹49/month to manage real-time expense budgets and financial records.',
              ),

            // 2. View Mode Selector [ Week ] [ Month ]
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242321) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedView = 'WEEK'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedView == 'WEEK' ? cardBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedView == 'WEEK'
                              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Text(
                          'Week',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedView == 'WEEK' ? FontWeight.w800 : FontWeight.w600,
                            color: _selectedView == 'WEEK' ? primaryColor : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedView = 'MONTH'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedView == 'MONTH' ? cardBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedView == 'MONTH'
                              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Text(
                          'Month',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedView == 'MONTH' ? FontWeight.w800 : FontWeight.w600,
                            color: _selectedView == 'MONTH' ? primaryColor : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Period Navigation < Previous  Current  Next >
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
    ),
  );
}
}
