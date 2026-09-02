import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../theme/app_theme.dart';
import 'analytics_metric_card.dart';
import 'analytics_insights_card.dart';
import 'analytics_empty_state.dart';

class ExpensesTabView extends StatelessWidget {
  final ExpenseAnalyticsData data;
  final VoidCallback onAddExpense;

  const ExpensesTabView({
    super.key,
    required this.data,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (data.totalSpent == 0 && data.totalIncome == 0 && data.categoryBreakdown.isEmpty) {
      return AnalyticsEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No Expense Records',
        message: 'Log your daily expenses and set a monthly budget to analyze spending distribution.',
        buttonLabel: 'Add Expense Transaction',
        onAction: onAddExpense,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.financeIcon;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;
    final cardBorder = isDark ? AppTheme.darkCardBorder : AppTheme.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TOP METRICS ROW
        Row(
          children: [
            Expanded(
              child: AnalyticsMetricCard(
                title: 'Total Spending',
                value: '₹${data.totalSpent.toStringAsFixed(0)}',
                subtitle: data.spendDeltaPercent != null ? '${data.spendDeltaPercent! > 0 ? "+" : ""}${data.spendDeltaPercent!.toStringAsFixed(1)}% vs prev' : 'This period',
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFFEF4444),
                deltaLabel: data.spendDeltaPercent != null ? '${data.spendDeltaPercent! > 0 ? "+" : ""}${data.spendDeltaPercent!.toStringAsFixed(0)}%' : null,
                isDeltaPositive: (data.spendDeltaPercent ?? 0) <= 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsMetricCard(
                title: 'Budget Remaining',
                value: data.monthlyBudget > 0 ? '₹${data.remainingBudget.toStringAsFixed(0)}' : 'No Budget',
                subtitle: data.monthlyBudget > 0 ? '${(data.budgetUtilization * 100).round()}% utilized' : 'Set in Finance',
                icon: Icons.savings_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. CATEGORY BREAKDOWN
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SPENDING BY CATEGORY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    '${data.categoryBreakdown.length} CATEGORIES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...data.categoryBreakdown.map((cat) {
                final pct = (cat.percentage * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cat.category,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '₹${cat.amount.toStringAsFixed(0)} ($pct%)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(cat.colorHex),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: cat.percentage,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(cat.colorHex)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. INSIGHTS
        AnalyticsInsightsCard(insights: data.insights),
      ],
    );
  }
}
