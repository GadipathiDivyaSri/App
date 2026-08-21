import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'goal_achieved_screen.dart';

class ShortTermPrioritiesScreen extends StatefulWidget {
  const ShortTermPrioritiesScreen({super.key});

  @override
  State<ShortTermPrioritiesScreen> createState() =>
      _ShortTermPrioritiesScreenState();
}

class _ShortTermPrioritiesScreenState extends State<ShortTermPrioritiesScreen> {
  List<Map<String, dynamic>> _priorities = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Short Term Priorities',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelPriorityIcon,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        children: [
          Text(
            'Short Term Priorities',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Focus on the next 7 days',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          ..._priorities.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return _buildPriorityCard(context, idx, item);
          }).toList(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPriorityCard(
      BuildContext context, int index, Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = item['isCompleted'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
        boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.cardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Accent Border
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isDark ? const Color(0xFF4C658A) : const Color(0xFF94A3B8))
                    : (isDark ? AppTheme.darkIconGlow : AppTheme.pastelPriorityIcon),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? (isDark ? AppTheme.darkTextSecondary : const Color(0xFF94A3B8))
                                  : (isDark
                                      ? Colors.white
                                      : AppTheme.lightTextPrimary),
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelPriorityIcon,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 14, color: Colors.white),
                          )
                        else
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: const Icon(Icons.edit_outlined,
                                    size: 18, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _priorities.removeAt(index);
                                  });
                                },
                                child: const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card Variant Details
                    if (item['type'] == 'progress') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PROGRESS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            '${((item['progress'] as double) * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: item['progress'] as double,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEEF2FF),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0D5CE5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GoalAchievedScreen(
                                goalTitle: item['title'] as String,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              item['dueText'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (item['type'] == 'streak') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: (item['days'] as List<String>)
                                .asMap()
                                .entries
                                .map((d) {
                              final dayIdx = d.key;
                              final dayName = d.value;
                              final isActive = (item['activeDays'] as List<int>)
                                  .contains(dayIdx);

                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? const Color(0xFF0D5CE5)
                                      : const Color(0xFFEEF2FF),
                                ),
                                child: Center(
                                  child: Text(
                                    dayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2B3D)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item['streak'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: Color(0xFF0D5CE5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (item['type'] == 'urgent') ...[
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            item['estTime'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            item['tag'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
