import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AnalyticsTabNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const AnalyticsTabNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  static const tabs = [
    'Overview',
    'Habits',
    'Studies',
    'Expenses',
    'Goals',
    'Milestones',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == tabs.length - 1 ? 0 : 0,
            ),
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor
                      : (isDark ? const Color(0xFF1E2235) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? activeColor
                        : (isDark ? AppTheme.darkCardBorder : Colors.transparent),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
