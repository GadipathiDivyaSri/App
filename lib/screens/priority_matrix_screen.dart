import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../providers/app_provider.dart';
import '../widgets/pro_feature_guard.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../theme/app_theme.dart';
import 'calendar_screen.dart';

class PriorityMatrixScreen extends StatefulWidget {
  const PriorityMatrixScreen({super.key});

  @override
  State<PriorityMatrixScreen> createState() => _PriorityMatrixScreenState();
}

class _PriorityMatrixScreenState extends State<PriorityMatrixScreen> {
  final List<Map<String, dynamic>> _p1Tasks = [
    {
      'id': 't_p1_1',
      'title': 'Complete Physics Thermodynamics Assignment',
      'tag': 'STUDY',
      'dueDate': DateTime.now(),
      'dueTime': const TimeOfDay(hour: 18, minute: 30),
      'priority': 1,
    },
    {
      'id': 't_p1_2',
      'title': 'Submit Mock Exam Test Series 04',
      'tag': 'EXAM',
      'dueDate': DateTime.now(),
      'dueTime': const TimeOfDay(hour: 21, minute: 0),
      'priority': 1,
    },
  ];

  final List<Map<String, dynamic>> _p2Tasks = [
    {
      'id': 't_p2_1',
      'title': 'Prepare Chemistry Organic Synthesis Notes',
      'tag': 'STUDY',
      'dueDate': DateTime.now().add(const Duration(days: 1)),
      'dueTime': const TimeOfDay(hour: 11, minute: 0),
      'priority': 2,
    },
    {
      'id': 't_p2_2',
      'title': 'Review Mathematics Calculus Formulas',
      'tag': 'PLANNING',
      'dueDate': DateTime.now().add(const Duration(days: 2)),
      'dueTime': const TimeOfDay(hour: 16, minute: 0),
      'priority': 2,
    },
  ];

  final List<Map<String, dynamic>> _p3Tasks = [
    {
      'id': 't_p3_1',
      'title': 'Organize Digital Workspace & Archive Question Banks',
      'tag': 'PERSONAL',
      'dueDate': DateTime.now().add(const Duration(days: 6)),
      'dueTime': const TimeOfDay(hour: 20, minute: 0),
      'priority': 3,
    },
  ];

  final List<Map<String, dynamic>> _completedTasks = [];
  bool _sortByUrgentTime = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ProFeatureGuard(
      feature: AppFeature.priorityMatrix,
      child: Scaffold(
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
        actions: [
          IconButton(
            tooltip: _sortByUrgentTime ? 'Group by Priority' : 'Sort by Deadline Time',
            icon: Icon(
              _sortByUrgentTime ? Icons.schedule_rounded : Icons.sort_rounded,
              color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
            ),
            onPressed: () {
              setState(() {
                _sortByUrgentTime = !_sortByUrgentTime;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_sortByUrgentTime
                      ? 'Sorted chronologically by nearest deadline'
                      : 'Grouped by Priority Matrix (P1 → P2 → P3)'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final provider = Provider.of<AppProvider>(context, listen: false);
          if (!provider.user.isPremium) {
            ProUpgradeDialog.showFeatureLockedDialog(context, AppFeature.priorityMatrix);
          } else {
            _showAddTaskModal(context);
          }
        },
        backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text(
          'Set Task & Deadline',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.pastelPriority,
                borderRadius: BorderRadius.circular(22),
                border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkIconBg : AppTheme.pastelPriorityIcon,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.flag_outlined,
                      color: isDark ? AppTheme.darkIconGlow : Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deadline-Driven Priorities',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mark task dates & deadlines to auto-structure your daily focus ⭐',
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

            // Upcoming Deadlines Summary Card
            _buildUpcomingDeadlinesCard(context),
            const SizedBox(height: 24),

            if (_sortByUrgentTime) ...[
              _buildChronologicalTasksSection(context),
            ] else ...[
              // Priority 1 Section
              _buildPriorityHeader(
                title: 'PRIORITY 1',
                subtitle: 'Urgent & Important (Due Today / Within 24h)',
                badgeCount: _p1Tasks.length.toString(),
                color: Colors.redAccent,
              ),
              const SizedBox(height: 10),
              _buildAddTaskButton(context, priorityLevel: 1),
              const SizedBox(height: 10),
              if (_p1Tasks.isEmpty)
                _buildEmptySectionCard(context, 'No urgent Priority 1 tasks.')
              else
                ..._getSortedTasks(_p1Tasks)
                    .map((t) => _buildPriorityTaskCard(context, t, Colors.redAccent, priorityLevel: 1)),
              const SizedBox(height: 24),

              // Priority 2 Section
              _buildPriorityHeader(
                title: 'PRIORITY 2',
                subtitle: 'Important (Due in 1–3 Days)',
                badgeCount: _p2Tasks.length.toString(),
                color: Colors.amber.shade800,
              ),
              const SizedBox(height: 10),
              _buildAddTaskButton(context, priorityLevel: 2),
              const SizedBox(height: 10),
              if (_p2Tasks.isEmpty)
                _buildEmptySectionCard(context, 'No medium priority tasks.')
              else
                ..._getSortedTasks(_p2Tasks)
                    .map((t) => _buildPriorityTaskCard(context, t, Colors.amber.shade800, priorityLevel: 2)),
              const SizedBox(height: 24),

              // Priority 3 Section
              _buildPriorityHeader(
                title: 'PRIORITY 3',
                subtitle: 'Flexible / Next Week & Later',
                badgeCount: _p3Tasks.length.toString(),
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 10),
              _buildAddTaskButton(context, priorityLevel: 3),
              const SizedBox(height: 10),
              if (_p3Tasks.isEmpty)
                _buildEmptySectionCard(context, 'No low priority tasks.')
              else
                ..._getSortedTasks(_p3Tasks)
                    .map((t) => _buildPriorityTaskCard(context, t, const Color(0xFF10B981), priorityLevel: 3)),
              const SizedBox(height: 24),
            ],

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
            const SizedBox(height: 70),
          ],
        ),
      ),
    ),
  );
}

  List<Map<String, dynamic>> _getSortedTasks(List<Map<String, dynamic>> tasks) {
    final list = List<Map<String, dynamic>>.from(tasks);
    list.sort((a, b) {
      final da = _getTaskFullDateTime(a);
      final db = _getTaskFullDateTime(b);
      return da.compareTo(db);
    });
    return list;
  }

  DateTime _getTaskFullDateTime(Map<String, dynamic> task) {
    final date = task['dueDate'] as DateTime? ?? DateTime.now();
    final time = task['dueTime'] as TimeOfDay? ?? const TimeOfDay(hour: 18, minute: 0);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget _buildChronologicalTasksSection(BuildContext context) {
    final allTasks = [..._p1Tasks, ..._p2Tasks, ..._p3Tasks];
    final sorted = _getSortedTasks(allTasks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriorityHeader(
          title: 'ALL TASKS BY DEADLINE',
          subtitle: 'Sorted Chronologically (Urgent First)',
          badgeCount: sorted.length.toString(),
          color: const Color(0xFF0D5CE5),
        ),
        const SizedBox(height: 14),
        if (sorted.isEmpty)
          _buildEmptySectionCard(context, 'No active tasks found.')
        else
          ...sorted.map((t) {
            final p = t['priority'] as int? ?? 1;
            final color = p == 1
                ? Colors.redAccent
                : (p == 2 ? Colors.amber.shade800 : const Color(0xFF10B981));
            return _buildPriorityTaskCard(context, t, color, priorityLevel: p);
          }),
        const SizedBox(height: 24),
      ],
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
    final now = DateTime.now();

    final allTasks = [..._p1Tasks, ..._p2Tasks, ..._p3Tasks];
    final todayCount = allTasks.where((t) {
      final dt = _getTaskFullDateTime(t);
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }).length;

    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowCount = allTasks.where((t) {
      final dt = _getTaskFullDateTime(t);
      return dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;
    }).length;

    final weekEnd = now.add(const Duration(days: 7));
    final thisWeekCount = allTasks.where((t) {
      final dt = _getTaskFullDateTime(t);
      return dt.isAfter(tomorrow) && dt.isBefore(weekEnd);
    }).length;

    final laterCount = allTasks.where((t) {
      final dt = _getTaskFullDateTime(t);
      return dt.isAfter(weekEnd);
    }).length;

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
                  Icon(Icons.timer_outlined, color: Color(0xFF0D5CE5), size: 22),
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
                      'Calendar View',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D5CE5),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFF0D5CE5), size: 18),
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
                  label: 'DUE TODAY',
                  count: todayCount.toString(),
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDeadlineBox(
                  context,
                  label: 'TOMORROW',
                  count: tomorrowCount.toString(),
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
                  count: thisWeekCount.toString(),
                  color: const Color(0xFF0D5CE5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDeadlineBox(
                  context,
                  label: 'LATER',
                  count: laterCount.toString(),
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
                fontSize: 14.5,
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
            borderRadius: BorderRadius.circular(12),
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
      onTap: () => _showAddTaskModal(context, defaultPriority: priorityLevel),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC7D2FE), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Color(0xFF0D5CE5), size: 18),
            const SizedBox(width: 6),
            Text(
              'Add Task & Pick Deadline',
              style: const TextStyle(
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
      BuildContext context, Map<String, dynamic> task, Color borderAccent, {int priorityLevel = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetDt = _getTaskFullDateTime(task);
    final now = DateTime.now();

    final isToday = targetDt.year == now.year && targetDt.month == now.month && targetDt.day == now.day;
    final isTomorrow = targetDt.year == now.add(const Duration(days: 1)).year &&
        targetDt.month == now.add(const Duration(days: 1)).month &&
        targetDt.day == now.add(const Duration(days: 1)).day;
    final isOverdue = targetDt.isBefore(now);

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isTomorrow) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = '${_monthName(targetDt.month)} ${targetDt.day}, ${targetDt.year}';
    }

    final time = task['dueTime'] as TimeOfDay? ?? const TimeOfDay(hour: 18, minute: 0);
    final timeStr = _formatTimeOfDay(time);

    String urgencyBadge;
    Color urgencyColor;
    if (isOverdue) {
      urgencyBadge = '🚨 OVERDUE';
      urgencyColor = Colors.red.shade700;
    } else if (isToday) {
      final diffHrs = targetDt.difference(now).inHours;
      urgencyBadge = diffHrs <= 0 ? '🚨 DUE SOON' : '⏰ TODAY (${diffHrs}h left)';
      urgencyColor = Colors.redAccent;
    } else if (isTomorrow) {
      urgencyBadge = '⏳ TOMORROW';
      urgencyColor = Colors.amber.shade800;
    } else {
      final diffDays = targetDt.difference(now).inDays;
      urgencyBadge = '📅 IN ${diffDays} DAYS';
      urgencyColor = const Color(0xFF0D5CE5);
    }

    final tag = task['tag'] as String? ?? 'STUDY';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? borderAccent.withOpacity(0.4) : Colors.transparent,
          width: 1.2,
        ),
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
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            task['title'] as String,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8), size: 18),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showEditTaskDialog(context, task, priorityLevel);
                            } else if (val == 'complete') {
                              setState(() {
                                _removeTaskFromList(task, priorityLevel);
                                _completedTasks.insert(0, {
                                  'title': task['title'],
                                  'tag': task['tag'],
                                });
                              });
                            } else if (val == 'delete') {
                              setState(() {
                                _removeTaskFromList(task, priorityLevel);
                              });
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_calendar_outlined,
                                      size: 18,
                                      color: isDark ? AppTheme.darkPrimary : const Color(0xFF0D5CE5)),
                                  const SizedBox(width: 8),
                                  const Text('Reschedule / Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'complete',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                                  SizedBox(width: 8),
                                  Text('Mark Completed'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                  SizedBox(width: 8),
                                  Text('Delete Task', style: TextStyle(color: Colors.redAccent)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_alarm_rounded, size: 14, color: Color(0xFF6366F1)),
                        const SizedBox(width: 5),
                        Text(
                          'Deadline: $dateLabel at $timeStr',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: urgencyColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            urgencyBadge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getTagBgColor(tag),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: _getTagTextColor(tag),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2B3D) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Priority $priorityLevel',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
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
                  color: isDark ? const Color(0xFF2A2B3D) : const Color(0xFFF1F5F9),
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
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
        ],
      ),
    );
  }

  void _showAddTaskModal(BuildContext context, {int? defaultPriority}) {
    final titleCtrl = TextEditingController();
    String selectedTag = 'STUDY';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    int assignedPriority = defaultPriority ?? _computePriorityFromDate(selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final now = DateTime.now();
          final isToday = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
          final isTomorrow = selectedDate.year == now.add(const Duration(days: 1)).year &&
              selectedDate.month == now.add(const Duration(days: 1)).month &&
              selectedDate.day == now.add(const Duration(days: 1)).day;

          String dateFormatted;
          if (isToday) {
            dateFormatted = 'Today (${_monthName(selectedDate.month)} ${selectedDate.day})';
          } else if (isTomorrow) {
            dateFormatted = 'Tomorrow (${_monthName(selectedDate.month)} ${selectedDate.day})';
          } else {
            dateFormatted = '${_monthName(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}';
          }

          final timeFormatted = _formatTimeOfDay(selectedTime);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Set Task & Deadline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Task Title
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'Enter task description or goal...',
                      prefixIcon: const Icon(Icons.task_alt_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Tag Selector
                  const Text(
                    'CATEGORY TAG',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['STUDY', 'WORK', 'EXAM', 'PLANNING', 'PERSONAL'].map((tag) {
                      final isSelected = selectedTag == tag;
                      return ChoiceChip(
                        label: Text(tag, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        selectedColor: isDark ? AppTheme.darkPrimary.withOpacity(0.3) : const Color(0xFFE0E7FF),
                        onSelected: (val) {
                          setModalState(() {
                            selectedTag = tag;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Date & Time Deadline Selector
                  const Text(
                    'MARK DEADLINE DATE & TIME',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Date Selector Button
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setModalState(() {
                                selectedDate = pickedDate;
                                assignedPriority = _computePriorityFromDate(selectedDate);
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2B3D) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF6366F1)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Deadline Date', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                      Text(dateFormatted, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Time Selector Button
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setModalState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2B3D) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF6366F1)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Deadline Time', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                      Text(timeFormatted, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Priority Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PRIORITY ASSIGNMENT',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                      ),
                      Text(
                        'Deadline suggests: P${_computePriorityFromDate(selectedDate)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriorityOption(
                        level: 1,
                        label: 'P1: Urgent (Today)',
                        color: Colors.redAccent,
                        isSelected: assignedPriority == 1,
                        onTap: () => setModalState(() => assignedPriority = 1),
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityOption(
                        level: 2,
                        label: 'P2: Upcoming (1-3d)',
                        color: Colors.amber.shade800,
                        isSelected: assignedPriority == 2,
                        onTap: () => setModalState(() => assignedPriority = 2),
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityOption(
                        level: 3,
                        label: 'P3: Later (>3d)',
                        color: const Color(0xFF10B981),
                        isSelected: assignedPriority == 3,
                        onTap: () => setModalState(() => assignedPriority = 3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Save Button
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
                              'id': 't_${DateTime.now().millisecondsSinceEpoch}',
                              'title': titleCtrl.text.trim(),
                              'tag': selectedTag,
                              'dueDate': selectedDate,
                              'dueTime': selectedTime,
                              'priority': assignedPriority,
                            };
                            if (assignedPriority == 1) _p1Tasks.add(newTask);
                            if (assignedPriority == 2) _p2Tasks.add(newTask);
                            if (assignedPriority == 3) _p3Tasks.add(newTask);
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text(
                        'Set Deadline & Save Task',
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
        },
      ),
    );
  }

  Widget _buildPriorityOption({
    required int level,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1.2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _computePriorityFromDate(DateTime date) {
    final now = DateTime.now();
    final diffDays = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diffDays <= 0) return 1;
    if (diffDays <= 2) return 2;
    return 3;
  }

  Color _getTagBgColor(String tag) {
    switch (tag) {
      case 'EXAM':
        return const Color(0xFFFEE2E2);
      case 'STUDY':
        return const Color(0xFFE0E7FF);
      case 'WORK':
        return const Color(0xFFFEF3C7);
      case 'PLANNING':
        return const Color(0xFFEDE9FE);
      case 'PERSONAL':
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  Color _getTagTextColor(String tag) {
    switch (tag) {
      case 'EXAM':
        return const Color(0xFFDC2626);
      case 'STUDY':
        return const Color(0xFF4338CA);
      case 'WORK':
        return const Color(0xFFD97706);
      case 'PLANNING':
        return const Color(0xFF7C3AED);
      case 'PERSONAL':
      default:
        return const Color(0xFF15803D);
    }
  }

  void _removeTaskFromList(Map<String, dynamic> task, int priorityLevel) {
    if (priorityLevel == 1) _p1Tasks.remove(task);
    if (priorityLevel == 2) _p2Tasks.remove(task);
    if (priorityLevel == 3) _p3Tasks.remove(task);
  }

  void _showEditTaskDialog(BuildContext context, Map<String, dynamic> task, int currentPriority) {
    final titleCtrl = TextEditingController(text: task['title'] as String);
    DateTime selectedDate = task['dueDate'] as DateTime? ?? DateTime.now();
    TimeOfDay selectedTime = task['dueTime'] as TimeOfDay? ?? const TimeOfDay(hour: 18, minute: 0);
    int selectedPriority = task['priority'] as int? ?? currentPriority;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Deadline & Priority', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                const Text('DEADLINE DATE & TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month, size: 14),
                        label: Text('${selectedDate.month}/${selectedDate.day}/${selectedDate.year}', style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 14),
                        label: Text(_formatTimeOfDay(selectedTime), style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setDialogState(() => selectedTime = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('PRIORITY LEVEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityOption(
                      level: 1,
                      label: 'P1: Urgent',
                      color: Colors.redAccent,
                      isSelected: selectedPriority == 1,
                      onTap: () => setDialogState(() => selectedPriority = 1),
                    ),
                    const SizedBox(width: 6),
                    _buildPriorityOption(
                      level: 2,
                      label: 'P2: Medium',
                      color: Colors.amber.shade800,
                      isSelected: selectedPriority == 2,
                      onTap: () => setDialogState(() => selectedPriority = 2),
                    ),
                    const SizedBox(width: 6),
                    _buildPriorityOption(
                      level: 3,
                      label: 'P3: Low',
                      color: const Color(0xFF10B981),
                      isSelected: selectedPriority == 3,
                      onTap: () => setDialogState(() => selectedPriority = 3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _removeTaskFromList(task, currentPriority);
                    task['title'] = titleCtrl.text.trim();
                    task['dueDate'] = selectedDate;
                    task['dueTime'] = selectedTime;
                    task['priority'] = selectedPriority;

                    if (selectedPriority == 1) _p1Tasks.add(task);
                    if (selectedPriority == 2) _p2Tasks.add(task);
                    if (selectedPriority == 3) _p3Tasks.add(task);
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
