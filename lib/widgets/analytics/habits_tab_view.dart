import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../theme/app_theme.dart';
import 'analytics_metric_card.dart';
import 'analytics_insights_card.dart';
import 'analytics_empty_state.dart';

class HabitsTabView extends StatelessWidget {
  final HabitAnalyticsData data;
  final VoidCallback onAddHabit;

  const HabitsTabView({
    super.key,
    required this.data,
    required this.onAddHabit,
  });

  @override
  Widget build(BuildContext context) {
    if (data.habitRankings.isEmpty) {
      return AnalyticsEmptyState(
        icon: Icons.spa_outlined,
        title: 'No Habit Data Available',
        message: 'Create and complete your daily habits to unlock consistency analytics and streak insights.',
        buttonLabel: 'Add Your First Habit',
        onAction: onAddHabit,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.personalGrowthIcon;
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
                title: 'Consistency Rate',
                value: '${(data.overallConsistency * 100).round()}%',
                subtitle: '${data.totalCompletions} completions',
                icon: Icons.donut_large_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsMetricCard(
                title: 'Best Streak',
                value: '${data.bestStreak} Days',
                subtitle: 'Record: ${data.longestStreak} days',
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. HABIT PERFORMANCE RANKINGS
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
                    'HABIT CONSISTENCY RANKINGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    '${data.habitRankings.length} TRACKED',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...data.habitRankings.map((h) {
                final pct = (h.consistencyRate * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              h.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text('🔥 ${h.streakDay}d', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                              const SizedBox(width: 8),
                              Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: primaryColor)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: h.consistencyRate,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            h.consistencyRate >= 0.8 ? const Color(0xFF10B981) : primaryColor,
                          ),
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

        // 3. INSIGHTS CARD
        AnalyticsInsightsCard(insights: data.insights),
      ],
    );
  }
}
