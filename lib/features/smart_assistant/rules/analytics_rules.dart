import 'package:flutter/material.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class AnalyticsRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    final focusScore = provider.user.focusScore;
    final streak = provider.user.activeStreak;
    final totalTasks = provider.tasks.length;
    final completedTasks = provider.tasks.where((t) => t.isCompleted).length;
    final totalHabits = provider.habits.length;
    final completedHabits = provider.habits.where((h) => h.isCompleted).length;

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📈 **Productivity & Focus Analytics**:\n• Focus Score: **$focusScore%**\n• Active Streak: **$streak Days**\n• Task Completion: **$completedTasks/$totalTasks**\n• Habit Consistency: **$completedHabits/$totalHabits**',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getDailyAnalytics,
      cardData: ActionCardData(
        type: ActionCardType.goalMeter,
        title: 'Focus Score: $focusScore%',
        subtitle: '$streak Days Active Consistency',
        items: [
          ActionCardItem(
            id: 'an_1',
            title: 'Task Execution',
            subtitle: '$completedTasks of $totalTasks tasks finished',
            trailingText: '$completedTasks/$totalTasks',
            icon: Icons.task_alt_rounded,
            iconColor: const Color(0xFF10B981),
          ),
          ActionCardItem(
            id: 'an_2',
            title: 'Habit Mastery',
            subtitle: '$completedHabits of $totalHabits habits checked today',
            trailingText: '$completedHabits/$totalHabits',
            icon: Icons.repeat_rounded,
            iconColor: const Color(0xFF0D5CE5),
          ),
        ],
      ),
      suggestionChips: ['What should I do now?', 'Plan my day', 'Show my tasks'],
    );
  }
}
