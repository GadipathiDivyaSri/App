import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../theme/app_theme.dart';
import 'analytics_metric_card.dart';
import 'analytics_insights_card.dart';
import 'analytics_empty_state.dart';

class StudiesTabView extends StatelessWidget {
  final StudyAnalyticsData data;
  final VoidCallback onAddSubject;

  const StudiesTabView({
    super.key,
    required this.data,
    required this.onAddSubject,
  });

  @override
  Widget build(BuildContext context) {
    if (data.totalStudyItems == 0 && data.subjectDistributions.isEmpty) {
      return AnalyticsEmptyState(
        icon: Icons.school_outlined,
        title: 'No Study Data Found',
        message: 'Add your subjects, assignments, and exam checkpoints to track your study performance patterns.',
        buttonLabel: 'Add Study Subject',
        onAction: onAddSubject,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.studiesIcon;
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
                title: 'Completion Rate',
                value: '${(data.completionRate * 100).round()}%',
                subtitle: '${data.completedStudyItems} of ${data.totalStudyItems} tasks',
                icon: Icons.assignment_turned_in_rounded,
                iconColor: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsMetricCard(
                title: 'Peak Study Day',
                value: data.mostProductiveDay ?? 'N/A',
                subtitle: 'Most assignments finished',
                icon: Icons.event_available_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. SUBJECT-WISE DISTRIBUTION
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
                    'SUBJECT FOCUS & COMPLETION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    '${data.subjectDistributions.length} SUBJECTS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...data.subjectDistributions.map((s) {
                final pct = (s.progress * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.subjectName,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '$pct% (${s.completedTasks}/${s.totalTasks})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(s.colorHex),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: s.progress,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(s.colorHex)),
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
