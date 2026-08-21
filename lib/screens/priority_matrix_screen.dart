import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'calendar_screen.dart';

class PriorityMatrixScreen extends StatefulWidget {
  const PriorityMatrixScreen({super.key});

  @override
  State<PriorityMatrixScreen> createState() => _PriorityMatrixScreenState();
}

class _PriorityMatrixScreenState extends State<PriorityMatrixScreen> {
  final List<Map<String, dynamic>> _p1Tasks = [];
  final List<Map<String, dynamic>> _p2Tasks = [];
  final List<Map<String, dynamic>> _p3Tasks = [];
  final List<Map<String, dynamic>> _completedTasks = [];

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
          'Priority Matrix',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Pastel / Dark Banner (Refer to Image 2)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.pastelPriority,
                borderRadius: BorderRadius.circular(22),
                border: isDark
                    ? Border.all(color: AppTheme.darkCardBorder, width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.asset(
                      'assets/icons/ic_priority.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkIconBg
                              : AppTheme.pastelPriorityIcon,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.flag_outlined,
                          color: isDark ? AppTheme.darkIconGlow : Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priority',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Priority Matrix ⭐',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Priority Matrix 2x2 Grid (Matching Reference Design)
            Text(
              'Priority Matrix',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.15,
              children: [
                // 1. Do First (Important & Urgent)
                _buildMatrixQuadrantCard(
                  title: 'Do First',
                  subtitle: 'Important &\nUrgent',
                  bgColor: isDark ? AppTheme.darkCardBg : AppTheme.pastelPersonalGrowth,
                  iconColor: isDark ? AppTheme.darkIconGlow : const Color(0xFF4A9B65),
                  icon: Icons.local_fire_department_rounded,
                  isDark: isDark,
                  taskCount: _p1Tasks.length,
                ),
                // 2. Schedule (Important but Not Urgent)
                _buildMatrixQuadrantCard(
                  title: 'Schedule',
                  subtitle: 'Important but\nNot Urgent',
                  bgColor: isDark ? AppTheme.darkCardBg : AppTheme.pastelStudies,
                  iconColor: isDark ? AppTheme.darkIconGlow : const Color(0xFFDCA432),
                  icon: Icons.hourglass_top_rounded,
                  isDark: isDark,
                  taskCount: _p2Tasks.length,
                ),
                // 3. Delegate (Not Important but Urgent)
                _buildMatrixQuadrantCard(
                  title: 'Delegate',
                  subtitle: 'Not Important but\nUrgent',
                  bgColor: isDark ? AppTheme.darkCardBg : AppTheme.pastelAnalytics,
                  iconColor: isDark ? AppTheme.darkIconGlow : const Color(0xFF4B8DBA),
                  icon: Icons.tune_rounded,
                  isDark: isDark,
                  taskCount: _p3Tasks.length,
                ),
                // 4. Eliminate (Not Important & Not Urgent)
                _buildMatrixQuadrantCard(
                  title: 'Eliminate',
                  subtitle: 'Not Important &\nNot Urgent',
                  bgColor: isDark ? AppTheme.darkCardBg : AppTheme.pastelPriority,
                  iconColor: isDark ? AppTheme.darkIconGlow : const Color(0xFFD25B67),
                  icon: Icons.outlined_flag_rounded,
                  isDark: isDark,
                  taskCount: 0,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Upcoming Deadlines Card
            _buildUpcomingDeadlinesCard(context),
            const SizedBox(height: 24),

            // Priority 1 Section
            _buildPriorityHeader(
              title: 'PRIORITY 1',
              subtitle: 'High Priority',
              badgeCount: _p1Tasks.length.toString(),
              color: Colors.redAccent,
            ),
            const SizedBox(height: 10),
            _buildAddTaskButton(context, priorityLevel: 1),
            const SizedBox(height: 10),
            if (_p1Tasks.isEmpty)
              _buildEmptySectionCard(context, 'No high priority tasks. Tap + Add Task to create one.')
            else
              ..._p1Tasks
                  .map((t) => _buildPriorityTaskCard(context, t, Colors.redAccent))
                  .toList(),
            const SizedBox(height: 24),

            // Priority 2 Section
            _buildPriorityHeader(
              title: 'PRIORITY 2',
              subtitle: 'Medium Priority',
              badgeCount: _p2Tasks.length.toString(),
              color: Colors.amber.shade800,
            ),
            const SizedBox(height: 10),
            _buildAddTaskButton(context, priorityLevel: 2),
            const SizedBox(height: 10),
            if (_p2Tasks.isEmpty)
              _buildEmptySectionCard(context, 'No medium priority tasks.')
            else
              ..._p2Tasks
                  .map((t) =>
                      _buildPriorityTaskCard(context, t, Colors.amber.shade800))
                  .toList(),
            const SizedBox(height: 24),

            // Priority 3 Section
            _buildPriorityHeader(
              title: 'PRIORITY 3',
              subtitle: 'Low Priority',
              badgeCount: _p3Tasks.length.toString(),
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 10),
            _buildAddTaskButton(context, priorityLevel: 3),
            const SizedBox(height: 10),
            if (_p3Tasks.isEmpty)
              _buildEmptySectionCard(context, 'No low priority tasks.')
            else
              ..._p3Tasks
                  .map((t) =>
                      _buildPriorityTaskCard(context, t, const Color(0xFF10B981)))
                  .toList(),
            const SizedBox(height: 24),

            // Completed History Section
            _buildPriorityHeader(
              title: 'COMPLETED HISTORY',
              subtitle: 'Recently Finished',
              badgeCount: _completedTasks.length.toString(),
              color: const Color(0xFF64748B),
              isArchive: true,
            ),
            const SizedBox(height: 12),
            if (_completedTasks.isEmpty)
              _buildEmptySectionCard(context, 'No completed tasks yet.')
            else
              ..._completedTasks.map((t) => _buildCompletedTaskCard(
                  context, t['title'] as String, t['tag'] as String? ?? 'DONE', const Color(0xFF10B981))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySectionCard(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _buildUpcomingDeadlinesCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.restore_page_outlined,
                      color: Color(0xFF0D5CE5), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Upcoming Deadlines',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CalendarScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'View Calendar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D5CE5),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF0D5CE5), size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDeadlineBox(
                  context,
                  label: 'TODAY',
                  count: _p1Tasks.length.toString(),
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDeadlineBox(
                  context,
                  label: 'TOMORROW',
                  count: _p2Tasks.length.toString(),
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDeadlineBox(
                  context,
                  label: 'THIS WEEK',
                  count: _p3Tasks.length.toString(),
                  color: const Color(0xFF0D5CE5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDeadlineBox(
                  context,
                  label: 'LATER',
                  count: _completedTasks.length.toString(),
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineBox(
    BuildContext context, {
    required String label,
    required String count,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2B3D) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'tasks',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityHeader({
    required String title,
    required String subtitle,
    required String badgeCount,
    required Color color,
    bool isArchive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isArchive ? Icons.check_circle_outline : Icons.flag_outlined,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Text(
            badgeCount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddTaskButton(BuildContext context, {required int priorityLevel}) {
    return GestureDetector(
      onTap: () => _showAddTaskModal(context, priorityLevel),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC7D2FE), style: BorderStyle.solid),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Color(0xFF0D5CE5), size: 18),
            SizedBox(width: 6),
            Text(
              'Add Task',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D5CE5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityTaskCard(
      BuildContext context, Map<String, dynamic> task, Color borderAccent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: borderAccent,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          task['title'] as String,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const Icon(Icons.more_horiz_rounded,
                            color: Color(0xFF94A3B8), size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          task['dueDate'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: task['tagColor'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task['tag'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: task['textColor'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTaskCard(
      BuildContext context, String title, String tag, Color tagColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2B3D)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF10B981), size: 22),
        ],
      ),
    );
  }

  Widget _buildMatrixQuadrantCard({
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
    required bool isDark,
    required int taskCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
        boxShadow: isDark
            ? AppTheme.darkCardShadow
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkIconBg : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (taskCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkIconBg : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$taskCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddTaskModal(BuildContext context, int priorityLevel) {
    final titleCtrl = TextEditingController();
    String tag = 'WORK';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.cardSurface,
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
              'Add Priority $priorityLevel Task',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
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
                  backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      final newTask = {
                        'title': titleCtrl.text.trim(),
                        'dueDate': 'Today, 5:00 PM',
                        'tag': tag,
                        'tagColor': const Color(0xFFE0F2FE),
                        'textColor': const Color(0xFF0284C7),
                      };
                      if (priorityLevel == 1) _p1Tasks.add(newTask);
                      if (priorityLevel == 2) _p2Tasks.add(newTask);
                      if (priorityLevel == 3) _p3Tasks.add(newTask);
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
