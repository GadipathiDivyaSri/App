import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Eisenhower Matrix Screen for WrindhaOS
/// 
/// 4 Quadrants:
/// 1. Urgent & Important (Do First)
/// 2. Not Urgent & Important (Schedule)
/// 3. Urgent & Not Important (Delegate)
/// 4. Not Urgent & Not Important (Eliminate)
class OrganizeMatrixScreen extends StatelessWidget {
  const OrganizeMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Eisenhower Matrix',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
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
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Organize by Urgency & Importance',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Focus on what matters most with the 4-quadrant decision model.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // 2x2 Quadrant Grid
            Column(
              children: [
                // Row 1: Q1 (Do First) & Q2 (Schedule)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildQuadrantCell(
                        context,
                        title: 'Do First',
                        subtitle: 'Urgent & Important',
                        bgColor: AppTheme.matrixDoFirst,
                        iconColor: const Color(0xFF10B981),
                        icon: Icons.priority_high_rounded,
                        tasks: q1Tasks,
                        priority: 1,
                        isPremium: isPremium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuadrantCell(
                        context,
                        title: 'Schedule',
                        subtitle: 'Important (Not Urgent)',
                        bgColor: AppTheme.matrixSchedule,
                        iconColor: const Color(0xFF3B82F6),
                        icon: Icons.calendar_today_rounded,
                        tasks: q2Tasks,
                        priority: 2,
                        isPremium: isPremium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Q3 (Delegate) & Q4 (Eliminate)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildQuadrantCell(
                        context,
                        title: 'Delegate',
                        subtitle: 'Urgent (Not Important)',
                        bgColor: AppTheme.matrixDelegate,
                        iconColor: const Color(0xFFF59E0B),
                        icon: Icons.people_outline_rounded,
                        tasks: q3Tasks,
                        priority: 3,
                        isPremium: isPremium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuadrantCell(
                        context,
                        title: 'Eliminate',
                        subtitle: 'Neither',
                        bgColor: AppTheme.matrixEliminate,
                        iconColor: const Color(0xFFEF4444),
                        icon: Icons.delete_outline_rounded,
                        tasks: q4Tasks,
                        priority: 4,
                        isPremium: isPremium,
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

  Widget _buildQuadrantCell(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
    required List<Task> tasks,
    required int priority,
    required bool isPremium,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context, listen: false);

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : bgColor,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
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
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No tasks here',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF94A3B8),
                  ),
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
                    color: isDark ? const Color(0xFF242321) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => provider.toggleTaskCompletion(task.id),
                        child: Icon(
                          task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: task.isCompleted ? const Color(0xFF10B981) : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showEditTaskDialog(context, tasks, idx);
                          } else if (val == 'complete') {
                            setState(() {
                              tasks[idx]['isCompleted'] = !isCompleted;
                            });
                          } else if (val == 'delete') {
                            setState(() {
                              tasks.removeAt(idx);
                            });
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.redAccent), SizedBox(width: 6), Text('Delete')]),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
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

  void _showEditTaskDialog(BuildContext context, List<Map<String, dynamic>> tasks, int idx) {
    final titleCtrl = TextEditingController(text: tasks[idx]['title'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Matrix Task', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter task title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = titleCtrl.text.trim();
              if (text.isNotEmpty) {
                final provider = Provider.of<AppProvider>(context, listen: false);
                provider.addTask(text, 'Eisenhower Matrix', 'Today', priority: priority);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }
}
