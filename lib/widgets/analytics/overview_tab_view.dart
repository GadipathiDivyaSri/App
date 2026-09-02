import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../theme/app_theme.dart';
import 'analytics_metric_card.dart';
import 'analytics_insights_card.dart';
import 'analytics_empty_state.dart';

class OverviewTabView extends StatelessWidget {
  final OverviewAnalyticsData data;
  final VoidCallback onNavigateToHabits;
  final VoidCallback onNavigateToStudies;
  final VoidCallback onNavigateToExpenses;
  final VoidCallback onNavigateToGoals;
  final VoidCallback onNavigateToMilestones;

  const OverviewTabView({
    super.key,
    required this.data,
    required this.onNavigateToHabits,
    required this.onNavigateToStudies,
    required this.onNavigateToExpenses,
    required this.onNavigateToGoals,
    required this.onNavigateToMilestones,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;
    final cardBorder = isDark ? AppTheme.darkCardBorder : AppTheme.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. OVERALL PROGRESS SCORE HERO BANNER
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E2238), const Color(0xFF2B2F4C)]
                  : [const Color(0xFF0D5CE5), const Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
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
                      'OVERALL PROGRESS SCORE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${data.overallProgressScore} / 100',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.overallProgressScore >= 75
                          ? 'Outstanding progress! Keep the momentum high 🔥'
                          : (data.overallProgressScore >= 40
                              ? 'Good progress. Steady consistency is key 🎯'
                              : 'Start logging habits and studies to boost your score ✨'),
                      style: const TextStyle(fontSize: 12.5, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${data.overallProgressScore}%',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. METRIC SUMMARY GRID
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onNavigateToHabits,
                child: AnalyticsMetricCard(
                  title: 'Habit Consistency',
                  value: '${(data.habitConsistency * 100).round()}%',
                  subtitle: 'Daily consistency',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onNavigateToStudies,
                child: AnalyticsMetricCard(
                  title: 'Study Tasks',
                  value: '${data.totalStudyTasksCompleted}',
                  subtitle: 'of ${data.totalStudyTasks} completed',
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onNavigateToExpenses,
                child: AnalyticsMetricCard(
                  title: 'Total Expenses',
                  value: '₹${data.totalExpenses.toStringAsFixed(0)}',
                  subtitle: data.remainingBudget > 0 ? '₹${data.remainingBudget.toStringAsFixed(0)} left' : 'No budget set',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onNavigateToGoals,
                child: AnalyticsMetricCard(
                  title: 'Goal Progress',
                  value: '${(data.goalProgress * 100).round()}%',
                  subtitle: '${data.milestonesAchieved} milestones hit',
                  icon: Icons.flag_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 3. PROGRESS TREND CHART CARD
        if (data.progressTrend.isNotEmpty) ...[
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
                      'DAILY ACTIVITY TREND',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: textSecondary,
                      ),
                    ),
                    Text(
                      'Habit Completions',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.progressTrend.map((pt) {
                    final maxVal = data.progressTrend.fold(0.0, (m, p) => p.value > m ? p.value : m);
                    final ratio = maxVal > 0 ? (pt.value / maxVal) : 0.0;
                    final barHeight = (ratio * 60).clamp(6.0, 60.0);

                    return Column(
                      children: [
                        Container(
                          width: 22,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: pt.isHighlight ? primaryColor : (pt.value > 0 ? const Color(0xFF10B981) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pt.label.split(' ')[0],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: pt.isHighlight ? FontWeight.bold : FontWeight.w500,
                            color: pt.isHighlight ? primaryColor : textSecondary,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 4. TOP INSIGHTS SECTION
        AnalyticsInsightsCard(insights: data.insights),
      ],
    );
  }
}
