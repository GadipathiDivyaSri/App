import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  List<Map<String, dynamic>> _habits = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.personalGrowthIcon;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Habit Tracker',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'habit_fab',
        backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () => _showAddHabitDialog(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Streaks Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Streaks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _habits.isEmpty ? '0 DAY STREAK' : '${_habits.where((h) => h['isCompleted'] == true).length} ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.personalGrowth,
                borderRadius: BorderRadius.circular(20),
                border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
              ),
              child: _habits.isEmpty
                  ? const Center(
                      child: Text(
                        'No active habit streaks yet.\nTap (+) below to create a habit and start Day 1!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        _habits.length > 3 ? 3 : _habits.length,
                        (idx) {
                          final h = _habits[idx];
                          final isDone = h['isCompleted'] == true;
                          final dayNum = (h['streakDay'] as int? ?? 1);
                          return _buildStreakDay('Day $dayNum', isDone: isDone);
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Rewards Earned Section
            Text(
              'Rewards earned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 14),

            _habits.where((h) => h['isCompleted'] == true).isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text(
                        'No rewards earned yet.\nComplete habit streaks to unlock badges & rewards!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildRewardCard(
                          context,
                          icon: Icons.workspace_premium_rounded,
                          label: 'EARLY BIRD',
                          bgColor: const Color(0xFFE0F2FE),
                          iconColor: const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 14),
                        _buildRewardCard(
                          context,
                          icon: Icons.local_fire_department_rounded,
                          label: 'ON FIRE',
                          bgColor: const Color(0xFFFEE2E2),
                          iconColor: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),

            // Active Habits Section
            Text(
              'Active Habits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 14),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];
                return _buildHabitCard(context, habit, index);
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakDay(String label, {bool isDone = false, bool isPending = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? const Color(0xFF0D5CE5)
                : (isPending ? const Color(0xFFE2E8F0) : Colors.transparent),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF0D5CE5)
                  : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          child: Icon(
            isDone
                ? Icons.check
                : (isPending ? Icons.more_horiz : Icons.circle_outlined),
            color: isDone ? Colors.white : const Color(0xFF64748B),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, Map<String, dynamic> habit, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = habit['isCompleted'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2B3D) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              habit['icon'] as IconData,
              color: const Color(0xFF0D5CE5),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit['title'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  habit['frequency'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _habits[index]['isCompleted'] = !isCompleted;
                if (!isCompleted) {
                  _habits[index]['streakDay'] = (_habits[index]['streakDay'] as int? ?? 0) + 1;
                }
              });
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFF0D5CE5) : Colors.transparent,
                border: Border.all(
                  color: const Color(0xFF0D5CE5),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF94A3B8)),
            onSelected: (val) {
              if (val == 'toggle') {
                setState(() {
                  _habits[index]['isCompleted'] = !isCompleted;
                });
              } else if (val == 'edit') {
                _showEditHabitDialog(context, index);
              } else if (val == 'delete') {
                setState(() {
                  _habits.removeAt(index);
                });
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(isCompleted ? Icons.undo_rounded : Icons.check_circle_outline, size: 18, color: const Color(0xFF0D5CE5)),
                    const SizedBox(width: 8),
                    Text(isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0D5CE5)),
                    SizedBox(width: 8),
                    Text('Edit Habit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Delete Habit', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditHabitDialog(BuildContext context, int index) {
    final titleCtrl = TextEditingController(text: _habits[index]['title'] as String);
    TimeOfDay preferredTime = const TimeOfDay(hour: 8, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Habit', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Habit Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time_rounded, size: 18),
                label: Text('Preferred Time: ${preferredTime.format(context)}'),
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: preferredTime);
                  if (picked != null) {
                    setDialogState(() => preferredTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _habits[index]['title'] = titleCtrl.text.trim();
                    _habits[index]['frequency'] = 'DAILY • ${preferredTime.format(context)}';
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    TimeOfDay preferredTime = const TimeOfDay(hour: 8, minute: 0);
    String selectedFrequency = 'Daily';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
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
                  const Text(
                    'Add New Habit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Habit Title',
                      hintText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'PREFERRED TIME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF0D5CE5)),
                          ),
                          icon: const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF0D5CE5)),
                          label: Text(
                            preferredTime.format(context),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D5CE5)),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: preferredTime,
                            );
                            if (picked != null) {
                              setModalState(() => preferredTime = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedFrequency,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'Weekdays', child: Text('Weekdays')),
                            DropdownMenuItem(value: 'Weekends', child: Text('Weekends')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedFrequency = val);
                          },
                        ),
                      ),
                    ],
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
                            _habits.add({
                              'id': DateTime.now().millisecondsSinceEpoch.toString(),
                              'title': titleCtrl.text.trim(),
                              'frequency': '${selectedFrequency.toUpperCase()} • ${preferredTime.format(context)}',
                              'icon': Icons.auto_awesome_rounded,
                              'isCompleted': false,
                              'streakDay': 1,
                            });
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text(
                        'Save Habit',
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
            );
          },
        );
      },
    );
  }
}
