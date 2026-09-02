import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../theme/app_theme.dart';
import 'analytics_metric_card.dart';
import 'analytics_insights_card.dart';
import 'analytics_empty_state.dart';

class GoalsTabView extends StatelessWidget {
  final GoalAnalyticsData data;
  final VoidCallback onAddGoal;

  const GoalsTabView({
    super.key,
    required this.data,
    required this.onAddGoal,
  });

  @override
  Widget build(BuildContext context) {
    if (data.totalGoals == 0 && data.goalItems.isEmpty) {
      return AnalyticsEmptyState(
        icon: Icons.flag_outlined,
        title: 'No Goals Configured',
        message: 'Set up your long-term career and life objectives in the Career Roadmap to track progression.',
        buttonLabel: 'Create Strategic Goal',
        onAction: onAddGoal,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;
    final cardBorder = isDark ? AppTheme.darkCardBorder : AppTheme.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TOP METRICS
        Row(
          children: [
            Expanded(
              child: AnalyticsMetricCard(
                title: 'On-Track Goals',
                value: '${data.onTrackGoals}',
                subtitle: 'of ${data.totalGoals} active goals',
                icon: Icons.verified_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsMetricCard(
                title: 'Completion Rate',
                value: '${(data.averageProgress * 100).round()}%',
                subtitle: '${data.completedGoals} completed',
                icon: Icons.track_changes_rounded,
                iconColor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. INDIVIDUAL GOAL PROGRESS CARDS
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
                    'GOAL PROGRESS TRACKER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    '${data.goalItems.length} GOALS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...data.goalItems.map((g) {
                final pct = (g.progress * 100).round();
                final isDone = g.isCompleted;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2235) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDone ? const Color(0xFF10B981).withOpacity(0.4) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              g.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF10B981).withOpacity(0.15)
                                  : const Color(0xFF3B82F6).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isDone ? 'Completed' : 'On Track',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isDone ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: g.progress,
                                minHeight: 6,
                                backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDone ? const Color(0xFF10B981) : primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDone ? const Color(0xFF10B981) : textSecondary,
                            ),
                          ),
                        ],
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
