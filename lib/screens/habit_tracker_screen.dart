import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../theme/app_theme.dart';

/// Habit Tracker Screen for WrindhaOS
/// 
/// Features:
/// - Daily, Weekdays, Weekends, and Custom Weekday frequency schedules
/// - Date Carousel / Navigator with history tracking
/// - Real-time Streak Engine (Current Streak 🔥, Longest Streak, Consistency Score)
/// - Pause, Resume, Edit, and Delete (with confirmation dialog)
/// - Dynamic Plan Limit enforcement (Free: Max 2 Habits, Pro: Unlimited)
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  DateTime _weekStartDate = DateTime.now().subtract(Duration(days: (DateTime.now().weekday - 1)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final selectedDate = provider.selectedHabitDate;
    final selectedDateStr = provider.selectedHabitDateStr;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final isViewingToday = selectedDateStr == todayStr;

    final habits = provider.habits.where((h) => h.status != 'archived').toList();
    final scheduledHabits = provider.scheduledHabitsForSelectedDate;
    final completedCount = provider.completedHabitsCountForSelectedDate;
    final progress = provider.habitProgressForSelectedDate;

    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.personalGrowthIcon;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;

    // Calculate active streaks across user habits
    final totalStreaks = habits.where((h) => h.streakDay > 0).length;
    final bestStreak = habits.fold<int>(0, (max, h) => h.longestStreak > max ? h.longestStreak : max);

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
        actions: [
          if (!isViewingToday)
            TextButton.icon(
              onPressed: () {
                provider.setSelectedHabitDate(DateTime.now());
                setState(() {
                  _weekStartDate = DateTime.now().subtract(Duration(days: (DateTime.now().weekday - 1)));
                });
              },
              icon: const Icon(Icons.today_rounded, size: 18),
              label: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'habit_fab',
        backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          if (!provider.canAddHabit) {
            ProUpgradeDialog.showHabitLimitDialog(context);
          } else {
            _showAddHabitDialog(context);
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Date Strip / Week Navigator
            _buildDateNavigator(context, isDark, provider),
            const SizedBox(height: 16),

            // 2. High-Impact Impressive Streaks Hero & Metrics Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2E1906), const Color(0xFF1E1408), const Color(0xFF15100B)]
                      : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.15 : 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streak Tier Badge & Flame Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$totalStreaks Active Streak${totalStreaks == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getStreakLevelTitle(bestStreak),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                        ),
                        child: Text(
                          '${(progress * 100).round()}% Today',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF59E0B),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 7-Day Streak Activity Bar Chart
                  _buildWeeklyStreakChart(context, isDark, provider),
                  const SizedBox(height: 20),

                  // Impressive 4-Stat Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildImpressiveStat(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFEF4444),
                        label: 'Active Flame',
                        value: '$totalStreaks 🔥',
                        isDark: isDark,
                      ),
                      _buildImpressiveStat(
                        icon: Icons.emoji_events_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Best Record',
                        value: '$bestStreak Days',
                        isDark: isDark,
                      ),
                      _buildImpressiveStat(
                        icon: Icons.check_circle_rounded,
                        iconColor: const Color(0xFF10B981),
                        label: 'Completed',
                        value: '$completedCount / ${scheduledHabits.length}',
                        isDark: isDark,
                      ),
                      _buildImpressiveStat(
                        icon: Icons.repeat_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        label: 'Total Habits',
                        value: '${habits.length}',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Habits Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isViewingToday ? "Today's Schedule" : "Scheduled Habits",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${scheduledHabits.length} SCHEDULED',
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

            // 4. Habits List
            if (habits.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.spa_outlined, size: 48, color: primaryColor.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No habits created yet.\nTap (+) below to start building your first habit!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, height: 1.4, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else if (scheduledHabits.isEmpty)
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
                    'No habits scheduled for this day.\nEnjoy your rest or select another date!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, height: 1.4),
                  ),
                ),
              )
            else
              Column(
                children: scheduledHabits.map((habit) {
                  final isDone = habit.isCompletedOnDate(selectedDateStr);
                  final isPaused = habit.status == 'paused';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDone
                            ? const Color(0xFF10B981).withOpacity(0.5)
                            : (isPaused
                                ? Colors.amber.withOpacity(0.3)
                                : (isDark ? AppTheme.darkCardBorder : AppTheme.borderLight)),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: isPaused
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Resume this habit to mark it completed.')),
                                  );
                                }
                              : () => provider.toggleHabit(habit.id, targetDate: selectedDate),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF10B981)
                                  : (isPaused ? Colors.amber.withOpacity(0.1) : Colors.transparent),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDone
                                    ? const Color(0xFF10B981)
                                    : (isPaused ? Colors.amber : textSecondary.withOpacity(0.6)),
                                width: 2,
                              ),
                            ),
                            child: isDone
                                ? const Icon(Icons.check, size: 20, color: Colors.white)
                                : (isPaused ? const Icon(Icons.pause, size: 16, color: Colors.amber) : null),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      habit.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isPaused ? textSecondary : textPrimary,
                                        decoration: isDone ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  if (isPaused)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'PAUSED',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${habit.streakDay} day streak • ${_formatFrequencyLabel(habit)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                  if (habit.category.isNotEmpty && habit.category != 'General') ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        habit.category,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                                      ),
                                    ),
                                  ],
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
                            } else if (action == 'pause') {
                              provider.pauseHabit(habit.id);
                            } else if (action == 'resume') {
                              provider.resumeHabit(habit.id);
                            } else if (action == 'delete') {
                              _showDeleteConfirmationDialog(context, habit);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')]),
                            ),
                            if (!isPaused)
                              const PopupMenuItem(
                                value: 'pause',
                                child: Row(children: [Icon(Icons.pause_circle_outline, size: 18), SizedBox(width: 8), Text('Pause')]),
                              )
                            else
                              const PopupMenuItem(
                                value: 'resume',
                                child: Row(children: [Icon(Icons.play_circle_outline, size: 18, color: Colors.green), SizedBox(width: 8), Text('Resume', style: TextStyle(color: Colors.green))]),
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

  Widget _buildDateNavigator(BuildContext context, bool isDark, AppProvider provider) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.personalGrowthIcon;
    final selectedDate = provider.selectedHabitDate;

    final weekDays = List.generate(7, (i) => _weekStartDate.add(Duration(days: i)));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: textPrimary),
              onPressed: () {
                setState(() {
                  _weekStartDate = _weekStartDate.subtract(const Duration(days: 7));
                });
              },
            ),
            Text(
              '${_formatMonthHeader(_weekStartDate)} - ${_formatMonthHeader(_weekStartDate.add(const Duration(days: 6)))}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: textPrimary),
              onPressed: () {
                setState(() {
                  _weekStartDate = _weekStartDate.add(const Duration(days: 7));
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (idx) {
            final dayDate = weekDays[idx];
            final isSelected = dayDate.year == selectedDate.year &&
                dayDate.month == selectedDate.month &&
                dayDate.day == selectedDate.day;
            final isToday = dayDate.year == DateTime.now().year &&
                dayDate.month == DateTime.now().month &&
                dayDate.day == DateTime.now().day;

            return Expanded(
              child: GestureDetector(
                onTap: () => provider.setSelectedHabitDate(dayDate),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? AppTheme.darkCardBg : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isToday ? primaryColor.withOpacity(0.5) : (isDark ? AppTheme.darkCardBorder : AppTheme.borderLight)),
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayNames[idx],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWeeklyStreakChart(BuildContext context, bool isDark, AppProvider provider) {
    final habits = provider.habits.where((h) => h.status != 'archived').toList();
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekDays = List.generate(7, (i) => _weekStartDate.add(Duration(days: i)));
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.25) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF78350F).withOpacity(0.5) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    '7-DAY STREAK ACTIVITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
              Text(
                'Weekly Velocity',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 7 Vertical Chart Columns
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (idx) {
                final d = weekDays[idx];
                final dStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
                
                final scheduledForDay = habits.where((h) => h.isScheduledForDate(d)).toList();
                final completedForDay = scheduledForDay.where((h) => h.isCompletedOnDate(dStr)).length;
                final rate = scheduledForDay.isEmpty ? 0.0 : (completedForDay / scheduledForDay.length);
                final barHeight = (rate * 50).clamp(6.0, 50.0);
                final isFull = rate >= 1.0 && scheduledForDay.isNotEmpty;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Top flame badge or percentage
                      if (isFull)
                        const Icon(Icons.local_fire_department_rounded, size: 13, color: Color(0xFFEF4444))
                      else
                        Text(
                          scheduledForDay.isEmpty ? '-' : '${(rate * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: rate > 0
                                ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                                : (isDark ? Colors.white30 : Colors.black26),
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Rounded Vertical Bar
                      Container(
                        width: 14,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: rate > 0
                              ? LinearGradient(
                                  colors: isFull
                                      ? [const Color(0xFFEF4444), const Color(0xFFF59E0B)]
                                      : [const Color(0xFFF59E0B), const Color(0xFF10B981)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                          color: rate > 0 ? null : (isDark ? Colors.white12 : Colors.black12),
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: isFull
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Day Label
                      Text(
                        dayLabels[idx],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                          color: isToday
                              ? const Color(0xFFF59E0B)
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getStreakLevelTitle(int bestStreak) {
    if (bestStreak >= 30) return '🌟 Supernova Master (30+ Days)';
    if (bestStreak >= 21) return '💎 Habit Solidified (21 Days)';
    if (bestStreak >= 14) return '⚡ Momentum Dynamo (2 Weeks)';
    if (bestStreak >= 7) return '🔥 Flame Ignition (7 Days)';
    if (bestStreak >= 3) return '✨ Rising Spark (3 Days)';
    if (bestStreak > 0) return '🌱 Momentum Initiated';
    return '🚀 Ready to Ignite Daily Habit';
  }

  Widget _buildImpressiveStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  String _formatFrequencyLabel(Habit habit) {
    final freq = habit.frequency.toUpperCase();
    if (freq == 'DAILY') return 'Daily';
    if (freq == 'WEEKDAYS') return 'Weekdays';
    if (freq == 'WEEKENDS') return 'Weekends';
    if (freq == 'WEEKLY') return 'Weekly';
    if (freq == 'CUSTOM') {
      final names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      final days = habit.selectedDays.map((d) => (d >= 1 && d <= 7) ? names[d - 1] : '').join(', ');
      return 'Custom ($days)';
    }
    return habit.frequency;
  }

  String _formatDisplayDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatMonthHeader(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showAddHabitDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'General';
    String frequency = 'DAILY';
    List<int> selectedDays = [1, 2, 3, 4, 5, 6, 7];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text('Add New Habit', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Read 20 pages',
                      labelText: 'Habit Title *',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'General', child: Text('General')),
                      DropdownMenuItem(value: 'Health & Fitness', child: Text('Health & Fitness')),
                      DropdownMenuItem(value: 'Study & Learning', child: Text('Study & Learning')),
                      DropdownMenuItem(value: 'Mindfulness', child: Text('Mindfulness')),
                      DropdownMenuItem(value: 'Productivity', child: Text('Productivity')),
                      DropdownMenuItem(value: 'Finance', child: Text('Finance')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'DAILY', child: Text('Every Day')),
                      DropdownMenuItem(value: 'WEEKDAYS', child: Text('Weekdays (Mon - Fri)')),
                      DropdownMenuItem(value: 'WEEKENDS', child: Text('Weekends (Sat - Sun)')),
                      DropdownMenuItem(value: 'CUSTOM', child: Text('Specific Days of Week')),
                      DropdownMenuItem(value: 'WEEKLY', child: Text('Once a Week')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() {
                          frequency = val;
                          if (val == 'WEEKDAYS') selectedDays = [1, 2, 3, 4, 5];
                          if (val == 'WEEKENDS') selectedDays = [6, 7];
                          if (val == 'DAILY') selectedDays = [1, 2, 3, 4, 5, 6, 7];
                        });
                      }
                    },
                  ),
                  if (frequency == 'CUSTOM') ...[
                    const SizedBox(height: 14),
                    const Text('Select Scheduled Days:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildWeekdaySelector(selectedDays, (days) {
                      setDlgState(() => selectedDays = days);
                    }),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Optional notes or motivation...',
                      labelText: 'Description (Optional)',
                    ),
                  ),
                ],
              ),
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
                    if (!provider.canAddHabit) {
                      Navigator.pop(ctx);
                      ProUpgradeDialog.showHabitLimitDialog(context);
                      return;
                    }
                    provider.addHabit(
                      Habit(
                        id: 'h_${DateTime.now().millisecondsSinceEpoch}',
                        title: text,
                        category: category,
                        frequency: frequency,
                        selectedDays: selectedDays,
                        description: descController.text.trim(),
                        startDate: DateTime.now().toIso8601String().split('T')[0],
                      ),
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Create Habit'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditHabitDialog(BuildContext context, Habit habit) {
    final titleController = TextEditingController(text: habit.title);
    final descController = TextEditingController(text: habit.description);
    String category = habit.category;
    String frequency = habit.frequency;
    List<int> selectedDays = List.from(habit.selectedDays);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

          return AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text('Edit Habit', style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Habit Title *'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'General', child: Text('General')),
                      DropdownMenuItem(value: 'Health & Fitness', child: Text('Health & Fitness')),
                      DropdownMenuItem(value: 'Study & Learning', child: Text('Study & Learning')),
                      DropdownMenuItem(value: 'Mindfulness', child: Text('Mindfulness')),
                      DropdownMenuItem(value: 'Productivity', child: Text('Productivity')),
                      DropdownMenuItem(value: 'Finance', child: Text('Finance')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'DAILY', child: Text('Every Day')),
                      DropdownMenuItem(value: 'WEEKDAYS', child: Text('Weekdays (Mon - Fri)')),
                      DropdownMenuItem(value: 'WEEKENDS', child: Text('Weekends (Sat - Sun)')),
                      DropdownMenuItem(value: 'CUSTOM', child: Text('Specific Days of Week')),
                      DropdownMenuItem(value: 'WEEKLY', child: Text('Once a Week')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDlgState(() {
                          frequency = val;
                          if (val == 'WEEKDAYS') selectedDays = [1, 2, 3, 4, 5];
                          if (val == 'WEEKENDS') selectedDays = [6, 7];
                          if (val == 'DAILY') selectedDays = [1, 2, 3, 4, 5, 6, 7];
                        });
                      }
                    },
                  ),
                  if (frequency == 'CUSTOM') ...[
                    const SizedBox(height: 14),
                    const Text('Select Scheduled Days:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildWeekdaySelector(selectedDays, (days) {
                      setDlgState(() => selectedDays = days);
                    }),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                ],
              ),
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
                    provider.editHabit(
                      habit.id,
                      title: text,
                      category: category,
                      frequency: frequency,
                      selectedDays: selectedDays,
                      description: descController.text.trim(),
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Habit?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete "${habit.title}"? All completion history and streak data will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              final provider = Provider.of<AppProvider>(context, listen: false);
              provider.deleteHabit(habit.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdaySelector(List<int> selectedDays, ValueChanged<List<int>> onChanged) {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (idx) {
        final dayNum = idx + 1;
        final isSelected = selectedDays.contains(dayNum);

        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(selectedDays);
            if (isSelected) {
              if (updated.length > 1) updated.remove(dayNum);
            } else {
              updated.add(dayNum);
            }
            onChanged(updated);
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF10B981) : Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                dayLabels[idx],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
