import 'package:flutter/material.dart';

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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Organise'),
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
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Prioritize tasks by urgency and importance in a 2x2 matrix table view.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // 2x2 Eisenhower Table Grid
            Column(
              children: [
                // Row 1: Q1 (Urgent & Important) | Q2 (Important but Not Urgent)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMatrixTableCell(
                        context,
                        title: 'Urgent & Important',
                        titleColor: const Color(0xFFEF4444),
                        borderColor: const Color(0xFFEF4444),
                        icon: Icons.priority_high_rounded,
                        tasks: _q1Tasks,
                        onAddTask: () => _showAddTaskDialog(context, 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMatrixTableCell(
                        context,
                        title: 'Important (Not Urgent)',
                        titleColor: const Color(0xFF0D5CE5),
                        borderColor: const Color(0xFF0D5CE5),
                        icon: Icons.calendar_today_rounded,
                        tasks: _q2Tasks,
                        onAddTask: () => _showAddTaskDialog(context, 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Q3 (Urgent but Not Important) | Q4 (Not Urgent & Not Important)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMatrixTableCell(
                        context,
                        title: 'Urgent (Not Important)',
                        titleColor: const Color(0xFFD97706),
                        borderColor: const Color(0xFFD97706),
                        icon: Icons.people_outline_rounded,
                        tasks: _q3Tasks,
                        onAddTask: () => _showAddTaskDialog(context, 3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMatrixTableCell(
                        context,
                        title: 'Neither (Delegate)',
                        titleColor: const Color(0xFF64748B),
                        borderColor: const Color(0xFFCBD5E1),
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
    required Color titleColor,
    required Color borderColor,
    required IconData icon,
    required List<Map<String, dynamic>> tasks,
    required VoidCallback onAddTask,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
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
                    Icon(icon, size: 16, color: titleColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
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
                    color: titleColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, size: 14, color: titleColor),
                ),
              ),
            ],
          ),
          const Divider(height: 16),

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
