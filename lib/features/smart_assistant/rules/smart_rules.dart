import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class SmartRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    switch (intent) {
      case SmartIntent.smartWhatToDoNow:
        return _whatToDoNow(provider);
      case SmartIntent.smartPlanMyDay:
        return _planMyDay(provider);
      case SmartIntent.smartFindFreeTime:
        return _findFreeTime(provider);
      case SmartIntent.smartOverloadCheck:
        return _overloadCheck(provider);
      case SmartIntent.smartDeadlineRisk:
        return _deadlineRisk(provider);
      case SmartIntent.smartMissedTaskRecovery:
        return _missedTaskRecovery(provider);
      default:
        return _whatToDoNow(provider);
    }
  }

  // ---------------------------------------------------------------------------
  // 1. WHAT SHOULD I DO NOW?
  // ---------------------------------------------------------------------------
  static AssistantMessage _whatToDoNow(AppProvider provider) {
    final pendingTasks = provider.tasks.where((t) => !t.isCompleted).toList();
    final pendingHabits = provider.habits.where((h) => !h.isCompleted).toList();
    final now = DateTime.now();

    // Deterministic Priority Scoring
    // Task Score = (4 - Priority) * 30 + DueTodayBonus(25) + OverdueBonus(40)
    Task? topTask;
    double highestScore = -1.0;

    for (final t in pendingTasks) {
      double score = (4 - t.priority) * 30.0;
      if (t.dueDateLabel.toLowerCase().contains('today')) {
        score += 25.0;
      }
      if (t.dueDate.isBefore(now) && t.dueDateLabel != 'Today') {
        score += 40.0; // Overdue urgency
      }
      if (score > highestScore) {
        highestScore = score;
        topTask = t;
      }
    }

    if (topTask != null) {
      final isHighPriority = topTask.priority == 1;
      final explanation = isHighPriority
          ? 'It is due **${topTask.dueDateLabel}** and is marked **high priority**.'
          : 'It has the highest calculated impact score on your daily roadmap.';

      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🎯 **Your Next Best Action** is **${topTask.title}**.\n$explanation\nEstimated deep focus time: **45 minutes**.',
        isUser: false,
        timestamp: DateTime.now(),
        detectedIntent: SmartIntent.smartWhatToDoNow,
        cardData: ActionCardData(
          type: ActionCardType.whatToDoRecommendation,
          title: topTask.title,
          subtitle: '${topTask.category} • Priority ${topTask.priority} • Due ${topTask.dueDateLabel}',
          items: [
            ActionCardItem(
              id: topTask.id,
              title: topTask.title,
              subtitle: '${topTask.category} • 45m Focus Block',
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFF0D5CE5),
            ),
          ],
          actions: [
            ActionButton(
              label: 'Start Focus (45m)',
              icon: Icons.play_circle_filled_rounded,
              commandPayload: 'START_FOCUS_SESSION_${topTask.id}',
            ),
            ActionButton(
              label: 'Mark Done',
              isPrimary: false,
              commandPayload: 'MARK_DONE_${topTask.id}',
            ),
          ],
        ),
        suggestionChips: [
          'Plan my day',
          'Show my tasks',
          'When am I free?',
        ],
      );
    }

    // If no tasks, check habits
    if (pendingHabits.isNotEmpty) {
      final topHabit = pendingHabits.first;
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🌱 All tasks completed! Your next best action is completing your **"${topHabit.title}"** daily habit.',
        isUser: false,
        timestamp: DateTime.now(),
        detectedIntent: SmartIntent.smartWhatToDoNow,
        cardData: ActionCardData(
          type: ActionCardType.habitList,
          title: topHabit.title,
          subtitle: 'Daily Habit • Streak: ${topHabit.streakDay} days',
          actions: [
            ActionButton(
              label: 'Mark Habit Completed',
              icon: Icons.check_circle_outline_rounded,
              commandPayload: 'MARK_HABIT_DONE_${topHabit.id}',
            ),
          ],
        ),
        suggestionChips: ['Plan my day', 'Show my habits'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎉 **You are 100% caught up!** Zero pending tasks and all daily habits finished. Relax or add a new goal!',
      isUser: false,
      timestamp: DateTime.now(),
      suggestionChips: ['Create a new goal', 'Write in my journal', 'Plan my day'],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. PLAN MY DAY
  // ---------------------------------------------------------------------------
  static AssistantMessage _planMyDay(AppProvider provider) {
    final pendingTasks = provider.tasks.where((t) => !t.isCompleted).take(3).toList();
    final pendingHabits = provider.habits.where((h) => !h.isCompleted).take(2).toList();

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📋 **Suggested Optimized Schedule for Today**:\n\n'
          '• **09:00 AM – 10:00 AM**: 🌅 Morning Habit Routine (${pendingHabits.isNotEmpty ? pendingHabits.first.title : "Meditation"})\n'
          '• **10:15 AM – 12:00 PM**: 🧠 Deep Focus Block: **${pendingTasks.isNotEmpty ? pendingTasks.first.title : "Core Studies"}**\n'
          '• **12:00 PM – 01:00 PM**: 🍽️ Lunch & Mental Break\n'
          '• **02:00 PM – 03:30 PM**: ⚡ Priority Task Block: **${pendingTasks.length > 1 ? pendingTasks[1].title : "Revision"}**\n'
          '• **04:30 PM – 06:00 PM**: 📚 Study Review & Exercises\n'
          '• **08:00 PM – 08:30 PM**: 📝 Evening Reflection & Journaling',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.smartPlanMyDay,
      cardData: ActionCardData(
        type: ActionCardType.schedulePlan,
        title: 'Optimized Daily Timeline',
        subtitle: '5.5 hours structured study & habits',
        items: [
          ActionCardItem(
            id: 'block_1',
            title: '10:15 AM – 12:00 PM',
            subtitle: 'Deep Work: ${pendingTasks.isNotEmpty ? pendingTasks.first.title : "Core Study"}',
            icon: Icons.lightbulb_outline_rounded,
            iconColor: const Color(0xFF0D5CE5),
          ),
          ActionCardItem(
            id: 'block_2',
            title: '02:00 PM – 03:30 PM',
            subtitle: 'Secondary Priority Execution',
            icon: Icons.task_alt_rounded,
            iconColor: const Color(0xFF10B981),
          ),
        ],
        actions: [
          ActionButton(
            label: 'Apply Schedule',
            icon: Icons.check_rounded,
            commandPayload: 'APPLY_DAY_PLAN',
          ),
          ActionButton(
            label: 'Cancel',
            isPrimary: false,
            commandPayload: 'CANCEL_ACTION',
          ),
        ],
      ),
      suggestionChips: ['What should I do now?', 'When am I free?', 'Show my tasks'],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. FIND FREE TIME
  // ---------------------------------------------------------------------------
  static AssistantMessage _findFreeTime(AppProvider provider) {
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '⏱️ **Available Free Bandwidth Today**:\n'
          '• **11:00 AM – 01:00 PM** (2 hrs open)\n'
          '• **03:30 PM – 05:00 PM** (1.5 hrs open)\n'
          '• **07:30 PM – 09:30 PM** (2 hrs open)\n\n'
          'You have **5.5 open hours** available for study or task execution.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.smartFindFreeTime,
      suggestionChips: ['Plan my day', 'What should I do now?'],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. OVERLOAD DETECTION
  // ---------------------------------------------------------------------------
  static AssistantMessage _overloadCheck(AppProvider provider) {
    final pendingCount = provider.tasks.where((t) => !t.isCompleted).length;
    final isOverloaded = pendingCount > 5;

    if (isOverloaded) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '⚠️ **Overload Detected!**\nYou have **$pendingCount pending tasks** estimated at ~7.5 hours of work, exceeding standard cognitive capacity for a single day.',
        isUser: false,
        timestamp: DateTime.now(),
        detectedIntent: SmartIntent.smartOverloadCheck,
        cardData: ActionCardData(
          type: ActionCardType.whatToDoRecommendation,
          title: 'Workload Warning',
          subtitle: 'Planned work exceeds available bandwidth',
          actions: [
            ActionButton(
              label: 'Reorganize My Day',
              icon: Icons.auto_fix_high_rounded,
              commandPayload: 'REORGANIZE_SCHEDULE',
            ),
          ],
        ),
        suggestionChips: ['Plan my day', 'Prioritize my tasks'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🟢 **Healthy Workload Balance**:\nYour current task volume ($pendingCount tasks) fits comfortably within your daily focus slots.',
      isUser: false,
      timestamp: DateTime.now(),
      suggestionChips: ['What should I do now?', 'Plan my day'],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. DEADLINE RISK DETECTION
  // ---------------------------------------------------------------------------
  static AssistantMessage _deadlineRisk(AppProvider provider) {
    final now = DateTime.now();
    final urgentTasks = provider.tasks.where((t) => !t.isCompleted && (t.dueDateLabel.contains('Today') || t.priority == 1)).toList();

    if (urgentTasks.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🛡️ **Zero Deadline Risk**:\nAll high priority deadlines are well within comfortable buffer margins.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my tasks', 'Plan my day'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🔴 **Urgent Deadline Alert**:\n**${urgentTasks.length} task(s)** are due today. Prioritize these before starting lower-priority milestones:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.smartDeadlineRisk,
      cardData: ActionCardData(
        type: ActionCardType.taskList,
        title: 'Approaching Deadlines',
        subtitle: '${urgentTasks.length} tasks due today',
        items: urgentTasks.map((t) => ActionCardItem(
          id: t.id,
          title: t.title,
          subtitle: 'Due Today • Priority ${t.priority}',
          icon: Icons.warning_rounded,
          iconColor: Colors.redAccent,
        )).toList(),
      ),
      suggestionChips: ['What should I do now?', 'Start Focus session'],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. MISSED TASK RECOVERY
  // ---------------------------------------------------------------------------
  static AssistantMessage _missedTaskRecovery(AppProvider provider) {
    final overdue = provider.tasks.where((t) => !t.isCompleted && t.dueDateLabel != 'Today').take(3).toList();

    if (overdue.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '✨ You have no overdue tasks to recover!',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🔄 **Overdue Task Recovery Plan**:\nI found **${overdue.length} overdue item(s)**. Suggested open slot for catch-up: **Tomorrow 02:00 PM**.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.smartMissedTaskRecovery,
      cardData: ActionCardData(
        type: ActionCardType.taskList,
        title: 'Overdue Recovery',
        subtitle: 'Reschedule to Tomorrow',
        items: overdue.map((t) => ActionCardItem(
          id: t.id,
          title: t.title,
          subtitle: 'Overdue',
          icon: Icons.restore_rounded,
          iconColor: Colors.amber,
        )).toList(),
        actions: [
          ActionButton(
            label: 'Reschedule All to Tomorrow',
            icon: Icons.update_rounded,
            commandPayload: 'RESCHEDULE_OVERDUE_TOMORROW',
          ),
        ],
      ),
      suggestionChips: ['Plan my day', 'What should I do now?'],
    );
  }
}
