import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../theme/app_theme.dart';

/// Habit Tracker Screen for WrindhaOS
/// 
/// Features:
/// - Today's Overview with Hero Circular/Radial Metric (◉ 4 / 6 Completed)
/// - Interactive Today's Habits list with status checkbox, emoji, and 🔥 streak badges
/// - Weekly Consistency 7-Day Matrix (M T W T F S S) with completion dot indicators
/// - 🔥 Best Streak Highlight Card
/// - Add, Edit, Pause, Resume, and Delete with dialogs
/// - Dynamic Plan Limit enforcement (Free: Max 2 Habits, Pro: Unlimited)
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  DateTime _weekStartDate = DateTime.now().subtract(Duration(days: (DateTime.now().weekday - 1)));

  String _getHabitEmoji(Habit habit) {
    final titleLower = habit.title.toLowerCase();
    final catLower = habit.category.toLowerCase();

    // Check if title already starts with an emoji
    if (habit.title.isNotEmpty) {
      final runes = habit.title.runes.toList();
      if (runes.isNotEmpty) {
        final firstChar = String.fromCharCode(runes.first);
        if (RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true).hasMatch(firstChar)) {
          return firstChar;
        }
      }
    }

    if (titleLower.contains('workout') || titleLower.contains('gym') || titleLower.contains('run') || titleLower.contains('exercise')) return '🏃';
    if (titleLower.contains('read') || titleLower.contains('book') || titleLower.contains('study') || titleLower.contains('pages')) return '📚';
    if (titleLower.contains('meditat') || titleLower.contains('yoga') || titleLower.contains('mindful') || titleLower.contains('breathe')) return '🧘';
    if (titleLower.contains('water') || titleLower.contains('drink') || titleLower.contains('hydrate')) return '💧';
    if (titleLower.contains('sleep') || titleLower.contains('wake') || titleLower.contains('bed')) return '🌙';
    if (titleLower.contains('code') || titleLower.contains('program') || titleLower.contains('dev')) return '💻';
    if (titleLower.contains('walk') || titleLower.contains('step')) return '🚶';
    if (titleLower.contains('eat') || titleLower.contains('diet') || titleLower.contains('meal') || titleLower.contains('food')) return '🥗';
    if (titleLower.contains('journal') || titleLower.contains('write') || titleLower.contains('diary')) return '✍️';
    if (titleLower.contains('math') || titleLower.contains('exam') || titleLower.contains('course')) return '📖';
    if (catLower.contains('fitness') || catLower.contains('health')) return '⚡';
    if (catLower.contains('mindfulness') || catLower.contains('mental')) return '🧘';
    if (catLower.contains('study') || catLower.contains('learning')) return '📚';

    return '🎯';
  }

  String _cleanHabitTitle(Habit habit) {
    final emoji = _getHabitEmoji(habit);
    String title = habit.title.trim();
    if (title.startsWith(emoji)) {
      title = title.substring(emoji.length).trim();
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final selectedDate = provider.selectedHabitDate;
    final selectedDateStr = provider.selectedHabitDateStr;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isViewingToday = selectedDateStr == todayStr;

    final habits = provider.habits.where((h) => h.status != 'archived').toList();
    final scheduledHabits = provider.scheduledHabitsForSelectedDate;
    final completedCount = provider.completedHabitsCountForSelectedDate;
    final progress = provider.habitProgressForSelectedDate;

    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.personalGrowthIcon;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;
    final cardBorder = isDark ? AppTheme.darkCardBorder : AppTheme.borderLight;

    // Determine top / best streak habit
    Habit? topHabit;
    int bestStreak = 0;
    for (final h in habits) {
      if (h.longestStreak > bestStreak || (h.longestStreak == bestStreak && topHabit == null)) {
        bestStreak = h.longestStreak;
        topHabit = h;
      }
    }
    if (topHabit == null && habits.isNotEmpty) {
      topHabit = habits.first;
      bestStreak = topHabit.longestStreak > 0 ? topHabit.longestStreak : topHabit.streakDay;
    }

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
          'Habits',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: () {
                if (!provider.canAddHabit) {
                  ProUpgradeDialog.showHabitLimitDialog(context);
                } else {
                  _showAddHabitDialog(context);
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO DATE & CIRCULAR PROGRESS CARD
            _buildHeroProgressCard(
              context: context,
              isDark: isDark,
              provider: provider,
              selectedDate: selectedDate,
              isViewingToday: isViewingToday,
              completedCount: completedCount,
              totalScheduled: scheduledHabits.length,
              progress: progress,
              primaryColor: primaryColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
            const SizedBox(height: 24),

            // 2. TODAY'S HABITS SECTION
            _buildTodayHabitsSection(
              context: context,
              isDark: isDark,
              provider: provider,
              habits: habits,
              scheduledHabits: scheduledHabits,
              selectedDateStr: selectedDateStr,
              selectedDate: selectedDate,
              isViewingToday: isViewingToday,
              primaryColor: primaryColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
            const SizedBox(height: 24),

            // 3. WEEKLY CONSISTENCY SECTION
            _buildWeeklyConsistencySection(
              context: context,
              isDark: isDark,
              provider: provider,
              habits: habits,
              primaryColor: primaryColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
            const SizedBox(height: 24),

            // 4. 🔥 BEST STREAK HIGHLIGHT CARD
            _buildBestStreakCard(
              isDark: isDark,
              topHabit: topHabit,
              bestStreak: bestStreak,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HERO PROGRESS CARD
  // ---------------------------------------------------------------------------
  Widget _buildHeroProgressCard({
    required BuildContext context,
    required bool isDark,
    required AppProvider provider,
    required DateTime selectedDate,
    required bool isViewingToday,
    required int completedCount,
    required int totalScheduled,
    required double progress,
    required Color primaryColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
  }) {
    final dateLabel = isViewingToday
        ? 'Today, ${DateFormat('MMM d').format(selectedDate)}'
        : DateFormat('EEEE, MMM d').format(selectedDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (!isViewingToday)
                GestureDetector(
                  onTap: () {
                    provider.setSelectedHabitDate(DateTime.now());
                    setState(() {
                      _weekStartDate = DateTime.now().subtract(Duration(days: (DateTime.now().weekday - 1)));
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Back to Today',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Radial Progress Indicator with ◉ 4 / 6 Completed
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: totalScheduled == 0 ? 0 : progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? const Color(0xFF10B981) : primaryColor,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lens_rounded,
                        size: 13,
                        color: progress >= 1.0 ? const Color(0xFF10B981) : primaryColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$completedCount / $totalScheduled',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Week Date Picker Strip
          _buildDateNavigator(context, isDark, provider),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. TODAY'S HABITS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildTodayHabitsSection({
    required BuildContext context,
    required bool isDark,
    required AppProvider provider,
    required List<Habit> habits,
    required List<Habit> scheduledHabits,
    required String selectedDateStr,
    required DateTime selectedDate,
    required bool isViewingToday,
    required Color primaryColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S HABITS",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: textSecondary,
                ),
              ),
              Text(
                '${scheduledHabits.length} ACTIVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List of Today's Habits
        if (habits.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.spa_outlined, size: 44, color: primaryColor.withOpacity(0.6)),
                  const SizedBox(height: 10),
                  Text(
                    'No habits created yet.\nTap (+ Add) above to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, height: 1.4, fontSize: 13.5),
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
              border: Border.all(color: cardBorder),
            ),
            child: Center(
              child: Text(
                'No habits scheduled for this day.\nEnjoy your rest or pick another date!',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, height: 1.4, fontSize: 13.5),
              ),
            ),
          )
        else
          Column(
            children: scheduledHabits.map((habit) {
              final isDone = habit.isCompletedOnDate(selectedDateStr);
              final isPaused = habit.status == 'paused';
              final emoji = _getHabitEmoji(habit);
              final cleanTitle = _cleanHabitTitle(habit);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF10B981).withOpacity(0.4)
                        : (isPaused ? Colors.amber.withOpacity(0.3) : cardBorder),
                    width: isDone ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isPaused
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Resume this habit to mark it complete.')),
                            );
                          }
                        : () => provider.toggleHabit(habit.id, targetDate: selectedDate),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Interactive Checkbox Circle (✓ or ○)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF10B981)
                                  : (isPaused ? Colors.amber.withOpacity(0.12) : Colors.transparent),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDone
                                    ? const Color(0xFF10B981)
                                    : (isPaused ? Colors.amber : (isDark ? Colors.white38 : const Color(0xFF94A3B8))),
                                width: isDone ? 2 : 1.8,
                              ),
                            ),
                            child: isDone
                                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                : (isPaused ? const Icon(Icons.pause_rounded, size: 14, color: Colors.amber) : null),
                          ),
                          const SizedBox(width: 12),

                          // Emoji Icon
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 10),

                          // Habit Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cleanTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isPaused
                                        ? textSecondary
                                        : (isDone ? textSecondary : textPrimary),
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                if (isPaused)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      'PAUSED',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Streak Badge: 🔥 12
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 3),
                                Text(
                                  '${habit.streakDay}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),

                          // More Options Popup
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, size: 18, color: textSecondary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. WEEKLY CONSISTENCY MATRIX SECTION
  // ---------------------------------------------------------------------------
  Widget _buildWeeklyConsistencySection({
    required BuildContext context,
    required bool isDark,
    required AppProvider provider,
    required List<Habit> habits,
    required Color primaryColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
  }) {
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekDays = List.generate(7, (i) => _weekStartDate.add(Duration(days: i)));
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'WEEKLY CONSISTENCY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Consistency Matrix Table Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Row: Habit Emoji space + M T W T F S S
              Row(
                children: [
                  const SizedBox(width: 36), // Space for emoji
                  Expanded(
                    child: Text(
                      'Habit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(7, (idx) {
                      final dayDate = weekDays[idx];
                      final isCurrentDay = dayDate.year == today.year &&
                          dayDate.month == today.month &&
                          dayDate.day == today.day;

                      return Container(
                        width: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        child: Text(
                          dayNames[idx],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrentDay ? FontWeight.w900 : FontWeight.w700,
                            color: isCurrentDay ? primaryColor : textSecondary,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              const SizedBox(height: 12),

              // Rows for each habit
              if (habits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No habits to track yet',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ),
                )
              else
                Column(
                  children: habits.map((habit) {
                    final emoji = _getHabitEmoji(habit);
                    final cleanTitle = _cleanHabitTitle(habit);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          // Emoji
                          SizedBox(
                            width: 32,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          // Title
                          Expanded(
                            child: Text(
                              cleanTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          // 7-day Dot indicators: ● / ○ / -
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(7, (idx) {
                              final dDate = weekDays[idx];
                              final dStr = '${dDate.year}-${dDate.month.toString().padLeft(2, '0')}-${dDate.day.toString().padLeft(2, '0')}';
                              final isScheduled = habit.isScheduledForDate(dDate);
                              final isCompleted = habit.isCompletedOnDate(dStr);

                              return GestureDetector(
                                onTap: () {
                                  if (isScheduled && habit.status != 'paused') {
                                    provider.toggleHabit(habit.id, targetDate: dDate);
                                  }
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  alignment: Alignment.center,
                                  child: isCompleted
                                      ? Container(
                                          width: 14,
                                          height: 14,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : (isScheduled
                                          ? Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
                                                  width: 2,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              '-',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: textSecondary.withOpacity(0.4),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. 🔥 BEST STREAK HIGHLIGHT CARD
  // ---------------------------------------------------------------------------
  Widget _buildBestStreakCard({
    required bool isDark,
    required Habit? topHabit,
    required int bestStreak,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
  }) {
    final habitTitle = topHabit != null ? _cleanHabitTitle(topHabit) : 'Daily Habit Consistency';
    final emoji = topHabit != null ? _getHabitEmoji(topHabit) : '🔥';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.15 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best Streak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$emoji $habitTitle • $bestStreak Days',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DATE STRIP SELECTOR
  // ---------------------------------------------------------------------------
  Widget _buildDateNavigator(BuildContext context, bool isDark, AppProvider provider) {
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.personalGrowthIcon;
    final selectedDate = provider.selectedHabitDate;

    final weekDays = List.generate(7, (i) => _weekStartDate.add(Duration(days: i)));
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
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
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : (isDark ? const Color(0xFF1E2235) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : (isToday ? primaryColor.withOpacity(0.5) : Colors.transparent),
                  width: isToday ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    dayNames[idx],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${dayDate.day}',
                    style: TextStyle(
                      fontSize: 13.5,
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
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOGS: ADD / EDIT / DELETE
  // ---------------------------------------------------------------------------
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
                      hintText: 'e.g. 🏃 Morning Workout',
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
                      hintText: 'Optional notes or goal target...',
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
