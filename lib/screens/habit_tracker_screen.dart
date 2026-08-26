import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Habit Tracker Screen for WrindhaOS
/// 
/// Manages:
/// - Habits CRUD (Create, Edit, Delete)
/// - Toggle completion & streak updates
/// - Completion history tracking
/// - Free Plan Limit (Max 2 habits)
/// - Zero Rewards Earned UI (completely removed as requested)
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final habits = provider.habits;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.personalGrowthIcon;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;

    final completedCount = habits.where((h) => h.isCompleted).length;
    final progress = habits.isEmpty ? 0.0 : (completedCount / habits.length);

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
          'Habit Tracker',
          style: TextStyle(
            color: textPrimary,
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
            // 1. Progress & Streak Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.personalGrowth,
                borderRadius: BorderRadius.circular(22),
                border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Habit Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedCount of ${habits.length} completed',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Active Habit Streaks Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Streaks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${habits.where((h) => h.streakDay > 0).length} STREAKS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (habits.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                ),
                child: Center(
                  child: Text(
                    'No habits added yet.\nTap (+) below to add your first habit!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, height: 1.4),
                  ),
                ),
              )
            else
              Column(
                children: habits.map((habit) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: habit.isCompleted
                            ? const Color(0xFF10B981).withOpacity(0.4)
                            : (isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => provider.toggleHabit(habit.id),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: habit.isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: habit.isCompleted ? const Color(0xFF10B981) : textSecondary,
                                width: 2,
                              ),
                            ),
                            child: habit.isCompleted
                                ? const Icon(Icons.check, size: 18, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.local_fire_department_rounded, size: 14, color: const Color(0xFFF59E0B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${habit.streakDay} day streak • ${habit.frequency}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 20, color: textSecondary),
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showEditHabitDialog(context, habit);
                            } else if (action == 'delete') {
                              provider.deleteHabit(habit.id);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')]),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.redAccent))]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final titleController = TextEditingController();
    String frequency = 'DAILY';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add New Habit', style: TextStyle(fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Read 20 pages',
                    labelText: 'Habit Title',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                    DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                    DropdownMenuItem(value: 'WEEKDAYS', child: Text('Weekdays')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => frequency = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = titleController.text.trim();
                  if (text.isNotEmpty) {
                    final provider = Provider.of<AppProvider>(context, listen: false);
                    provider.addHabit(
                      Habit(
                        id: 'h_${DateTime.now().millisecondsSinceEpoch}',
                        title: text,
                        frequency: frequency,
                      ),
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Habit'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditHabitDialog(BuildContext context, Habit habit) {
    final titleController = TextEditingController(text: habit.title);
    String frequency = habit.frequency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Habit', style: TextStyle(fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Habit Title'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                    DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                    DropdownMenuItem(value: 'WEEKDAYS', child: Text('Weekdays')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => frequency = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = titleController.text.trim();
                  if (text.isNotEmpty) {
                    final provider = Provider.of<AppProvider>(context, listen: false);
                    provider.editHabit(habit.id, text, frequency);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
