import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../theme/app_theme.dart';

class AnalyticsInsightsCard extends StatelessWidget {
  final List<AnalyticsInsight> insights;

  const AnalyticsInsightsCard({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;
    final cardBorder = isDark ? AppTheme.darkCardBorder : AppTheme.borderLight;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                'AI & ACTIVITY INSIGHTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...insights.map((ins) {
            Color sentimentColor;
            switch (ins.sentiment) {
              case InsightSentiment.positive:
                sentimentColor = const Color(0xFF10B981);
                break;
              case InsightSentiment.warning:
                sentimentColor = const Color(0xFFF59E0B);
                break;
              case InsightSentiment.info:
              case InsightSentiment.neutral:
                sentimentColor = const Color(0xFF3B82F6);
                break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sentimentColor.withOpacity(isDark ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sentimentColor.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(ins.icon, size: 18, color: sentimentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ins.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ins.message,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
