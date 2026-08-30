import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/pro_feature_guard.dart';
import '../widgets/premium_lock_banner.dart';
import '../theme/app_theme.dart';

/// Analytics Screen for WrindhaOS
/// 
/// Supports 4 distinct period aggregations:
/// 1. [ 10 Days ] - Most recent 10 days
/// 2. [ Week ] - Selected 7-day week
/// 3. [ Month ] - Selected 30-day month
/// 4. [ Year ] - 12-month annual view
/// Uses real user data from AppProvider without fake stats.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // '10_DAYS', 'WEEK', 'MONTH', 'YEAR'
  String _selectedPeriod = '10_DAYS';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final isPremium = provider.user.isPremium;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;

    // Filter data according to selected period
    final now = DateTime.now();
    int daysLimit = 10;
    if (_selectedPeriod == '10_DAYS') daysLimit = 10;
    if (_selectedPeriod == 'WEEK') daysLimit = 7;
    if (_selectedPeriod == 'MONTH') daysLimit = 30;
    if (_selectedPeriod == 'YEAR') daysLimit = 365;

    final cutoffDate = now.subtract(Duration(days: daysLimit));

    final periodTasks = provider.tasks.where((t) => !t.dueDate.isBefore(cutoffDate)).toList();
    final completedTasks = periodTasks.where((t) => t.isCompleted).length;
    final taskCompletionRate = periodTasks.isEmpty ? 0.0 : (completedTasks / periodTasks.length);

    final periodExpenses = provider.expenses.where((e) => !e.date.isBefore(cutoffDate)).toList();
    final totalSpent = periodExpenses.where((e) => !e.isIncome).fold(0.0, (sum, e) => sum + e.amount);

    final habits = provider.habits;
    final completedHabits = habits.where((h) => h.isCompleted).length;
    final habitRate = habits.isEmpty ? 0.0 : (completedHabits / habits.length);

    final subjects = provider.subjects;
    final avgStudyProgress = subjects.isEmpty
        ? 0.0
        : (subjects.fold(0.0, (sum, s) => sum + s.progress) / subjects.length);

    // Productivity Score = weighted average of task completion (40%), habits (40%), study progress (20%)
    final prodScore = ((taskCompletionRate * 0.4 + habitRate * 0.4 + avgStudyProgress * 0.2) * 100).round();

    return ProFeatureGuard(
      feature: AppFeature.analytics,
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
            'Analytics & Insights',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            // 2. Period Selector [ 10 Days ] [ Week ] [ Month ] [ Year ]
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242321) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  _buildPeriodTab('10_DAYS', '10 Days', isDark, cardBg, textSecondary, primaryColor),
                  _buildPeriodTab('WEEK', 'Week', isDark, cardBg, textSecondary, primaryColor),
                  _buildPeriodTab('MONTH', 'Month', isDark, cardBg, textSecondary, primaryColor),
                  _buildPeriodTab('YEAR', 'Year', isDark, cardBg, textSecondary, primaryColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Top Productivity Score Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1F30), const Color(0xFF2A2B42)]
                      : [const Color(0xFF0D5CE5), const Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF0D5CE5)).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRODUCTIVITY SCORE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$prodScore / 100',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prodScore >= 70 ? 'Excellent momentum! Keep it going 🔥' : 'Good start. Consistent focus is key 🎯',
                          style: const TextStyle(fontSize: 12.5, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$prodScore%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Metric Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Habit Consistency',
                    '${(habitRate * 100).round()}%',
                    '${habits.where((h) => h.streakDay > 0).length} active streaks',
                    const Color(0xFF10B981),
                    Icons.spa_rounded,
                    cardBg,
                    isDark,
                    textPrimary,
                    textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Task Completion',
                    '${(taskCompletionRate * 100).round()}%',
                    '$completedTasks of ${periodTasks.length} tasks',
                    const Color(0xFF3B82F6),
                    Icons.task_alt_rounded,
                    cardBg,
                    isDark,
                    textPrimary,
                    textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Study Progress',
                    '${(avgStudyProgress * 100).round()}%',
                    '${subjects.length} enrolled subjects',
                    const Color(0xFF8B5CF6),
                    Icons.school_rounded,
                    cardBg,
                    isDark,
                    textPrimary,
                    textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Period Spending',
                    '₹${totalSpent.toStringAsFixed(0)}',
                    '${periodExpenses.length} transactions',
                    const Color(0xFFF59E0B),
                    Icons.account_balance_wallet_outlined,
                    cardBg,
                    isDark,
                    textPrimary,
                    textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Insights Breakdown Card
            Text(
              'Performance Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  _buildProgressRow('Habit Execution', habitRate, const Color(0xFF10B981), textPrimary, textSecondary, isDark),
                  const SizedBox(height: 14),
                  _buildProgressRow('Task Goals Done', taskCompletionRate, const Color(0xFF3B82F6), textPrimary, textSecondary, isDark),
                  const SizedBox(height: 14),
                  _buildProgressRow('Academic Milestones', avgStudyProgress, const Color(0xFF8B5CF6), textPrimary, textSecondary, isDark),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPeriodTab(String key, String label, bool isDark, Color cardBg, Color textSecondary, Color primaryColor) {
    final isSelected = _selectedPeriod == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? primaryColor : textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String stat,
    String subtitle,
    Color color,
    IconData icon,
    Color cardBg,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Icon(Icons.trending_up_rounded, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Text(stat, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildThreeColumnStatCard({
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
        boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    String title,
    double value,
    Color color,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary)),
            Text('${(value * 100).round()}%', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: isDark ? Colors.white10 : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// LEGEND ITEM
// =============================================================================

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
      ],
    );
  }
}

