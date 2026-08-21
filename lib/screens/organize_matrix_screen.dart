import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OrganizeMatrixScreen extends StatefulWidget {
  const OrganizeMatrixScreen({super.key});

  @override
  State<OrganizeMatrixScreen> createState() => _OrganizeMatrixScreenState();
}

class _OrganizeMatrixScreenState extends State<OrganizeMatrixScreen> {
  final List<Map<String, dynamic>> _q1Tasks = [];
  final List<Map<String, dynamic>> _q2Tasks = [];
  final List<Map<String, dynamic>> _q3Tasks = [];
  final List<Map<String, dynamic>> _q4Tasks = [];

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
          'Organise',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRODUCTIVITY STRATEGY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Eisenhower Matrix Table',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prioritize tasks by urgency and importance in a 2x2 matrix table view.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // 2x2 Eisenhower Table Grid with Exact Filled Pastel Colors
            Column(
              children: [
                // Row 1: Q1 (Do First: #CFE8D5) | Q2 (Schedule: #F8DFA6)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMatrixTableCell(
                        context,
                        title: 'Do First',
                        subtitle: 'Urgent & Important',
                        bgColor: AppTheme.matrixDoFirst,
                        iconColor: AppTheme.pastelGrowthIcon,
                        icon: Icons.priority_high_rounded,
                        tasks: _q1Tasks,
                        onAddTask: () => _showAddTaskDialog(context, 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMatrixTableCell(
                        context,
                        title: 'Schedule',
                        subtitle: 'Important (Not Urgent)',
                        bgColor: AppTheme.matrixSchedule,
                        iconColor: AppTheme.pastelStudiesIcon,
                        icon: Icons.calendar_today_rounded,
                        tasks: _q2Tasks,
                        onAddTask: () => _showAddTaskDialog(context, 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Q3 (Delegate: #C4D9E8) | Q4 (Eliminate: #E8B8BC)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMatrixTableCell(
                        context,
                        title: 'Delegate',
                        subtitle: 'Urgent (Not Important)',
                        bgColor: AppTheme.matrixDelegate,
                        iconColor: AppTheme.pastelAnalyticsIcon,
                        icon: Icons.people_outline_rounded,
                        tasks: _q3Tasks,
                        onAddTask: () => _showAddTaskDialog(context, 3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMatrixTableCell(
                        context,
                        title: 'Eliminate',
                        subtitle: 'Neither',
                        bgColor: AppTheme.matrixEliminate,
                        iconColor: AppTheme.pastelPriorityIcon,
                        icon: Icons.delete_outline_rounded,
                        tasks: _q4Tasks,
                        onAddTask: () => _showAddTaskDialog(context, 4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixTableCell(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
    required List<Map<String, dynamic>> tasks,
    required VoidCallback onAddTask,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : bgColor,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
        boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cell Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: isDark ? AppTheme.darkIconGlow : iconColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAddTask,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkIconBg : Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, size: 14, color: isDark ? AppTheme.darkIconGlow : iconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tasks List
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'No tasks',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...tasks.asMap().entries.map((entry) {
              final idx = entry.key;
              final t = entry.value;
              final isCompleted = t['isCompleted'] == true;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    tasks[idx]['isCompleted'] = !isCompleted;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2B3D)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isCompleted
                                ? const Color(0xFF0D5CE5)
                                : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                          color: isCompleted
                              ? const Color(0xFF0D5CE5)
                              : Colors.transparent,
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? const Color(0xFF94A3B8)
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, int qNumber) {
    final titleCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Task to Quadrant $qNumber',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Task Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5CE5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      final item = {
                        'title': titleCtrl.text.trim(),
                        'isCompleted': false,
                      };
                      if (qNumber == 1) _q1Tasks.add(item);
                      if (qNumber == 2) _q2Tasks.add(item);
                      if (qNumber == 3) _q3Tasks.add(item);
                      if (qNumber == 4) _q4Tasks.add(item);
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text(
                  'Save Task',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
