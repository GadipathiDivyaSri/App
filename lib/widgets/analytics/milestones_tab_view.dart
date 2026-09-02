import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../theme/app_theme.dart';
import 'analytics_metric_card.dart';
import 'analytics_insights_card.dart';
import 'analytics_empty_state.dart';

class MilestonesTabView extends StatelessWidget {
  final MilestoneAnalyticsData data;
  final VoidCallback onAddMilestone;

  const MilestonesTabView({
    super.key,
    required this.data,
    required this.onAddMilestone,
  });

  @override
  Widget build(BuildContext context) {
    if (data.totalMilestones == 0) {
      return AnalyticsEmptyState(
        icon: Icons.military_tech_outlined,
        title: 'No Milestones Tracked',
        message: 'Add career milestones and learning achievements to view your journey timeline.',
        buttonLabel: 'Add Milestone Checkpoint',
        onAction: onAddMilestone,
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
                title: 'Completed',
                value: '${data.completedMilestones}',
                subtitle: 'Milestones achieved',
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnalyticsMetricCard(
                title: 'In Progress',
                value: '${data.inProgressMilestones}',
                subtitle: '${data.upcomingMilestones} upcoming',
                icon: Icons.timelapse_rounded,
                iconColor: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. MILESTONE SECTIONS (Completed, In Progress, Upcoming)
        if (data.completedList.isNotEmpty) ...[
          _buildMilestoneSectionHeader('COMPLETED MILESTONES', const Color(0xFF10B981), textSecondary),
          const SizedBox(height: 8),
          ...data.completedList.map((m) => _buildMilestoneTile(m, true, isDark, cardBg, cardBorder, textPrimary, textSecondary)),
          const SizedBox(height: 16),
        ],

        if (data.inProgressList.isNotEmpty) ...[
          _buildMilestoneSectionHeader('IN PROGRESS', const Color(0xFFF59E0B), textSecondary),
          const SizedBox(height: 8),
          ...data.inProgressList.map((m) => _buildMilestoneTile(m, false, isDark, cardBg, cardBorder, textPrimary, textSecondary)),
          const SizedBox(height: 16),
        ],

        if (data.upcomingList.isNotEmpty) ...[
          _buildMilestoneSectionHeader('UPCOMING TARGETS', const Color(0xFF3B82F6), textSecondary),
          const SizedBox(height: 8),
          ...data.upcomingList.map((m) => _buildMilestoneTile(m, false, isDark, cardBg, cardBorder, textPrimary, textSecondary)),
          const SizedBox(height: 16),
        ],

        // 3. INSIGHTS
        AnalyticsInsightsCard(insights: data.insights),
      ],
    );
  }

  Widget _buildMilestoneSectionHeader(String title, Color accentColor, Color textSecondary) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneTile(
    MilestoneItemAnalytics m,
    bool isCompleted,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? const Color(0xFF10B981).withOpacity(0.4) : cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF10B981) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? const Color(0xFF10B981) : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                width: 1.8,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              m.title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              m.category,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
