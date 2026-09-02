import 'package:flutter/material.dart';
import '../../models/analytics_models.dart';
import '../../theme/app_theme.dart';

class AnalyticsDateFilterBar extends StatelessWidget {
  final AnalyticsDateRangeType selectedType;
  final ValueChanged<AnalyticsDateRangeType> onSelectType;
  final VoidCallback onCustomDatePicked;

  const AnalyticsDateFilterBar({
    super.key,
    required this.selectedType,
    required this.onSelectType,
    required this.onCustomDatePicked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final filters = [
      {'type': AnalyticsDateRangeType.thisWeek, 'label': 'This Week'},
      {'type': AnalyticsDateRangeType.thisMonth, 'label': 'This Month'},
      {'type': AnalyticsDateRangeType.lastMonth, 'label': 'Last Month'},
      {'type': AnalyticsDateRangeType.custom, 'label': 'Custom'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181B2A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
      ),
      child: Row(
        children: filters.map((item) {
          final t = item['type'] as AnalyticsDateRangeType;
          final label = item['label'] as String;
          final isSelected = selectedType == t;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (t == AnalyticsDateRangeType.custom) {
                  onCustomDatePicked();
                } else {
                  onSelectType(t);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppTheme.darkCardBg : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? (isDark ? Colors.white : primaryColor) : textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
