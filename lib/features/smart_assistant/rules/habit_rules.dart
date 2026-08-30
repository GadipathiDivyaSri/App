import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class HabitRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    switch (intent) {
      case SmartIntent.createHabit:
        return _createHabit(entities, provider);
      case SmartIntent.completeHabit:
        return _completeHabit(entities, provider, isComplete: true);
      case SmartIntent.uncompleteHabit:
        return _completeHabit(entities, provider, isComplete: false);
      case SmartIntent.deleteHabit:
        return _deleteHabit(entities, provider);
      case SmartIntent.getHabitStreak:
        return _getHabitStreak(provider);
      case SmartIntent.getPendingHabits:
        return _getPendingHabits(provider);
      case SmartIntent.getHabits:
      default:
        return _getAllHabits(provider);
    }
  }

  static AssistantMessage _createHabit(ExtractedEntities entities, AppProvider provider) {
    if (!provider.canAddHabit) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🔒 Free tier limit reached (2 habits max). Upgrade to Pro for unlimited habits!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my habits', 'Show my tasks'],
      );
    }

    final title = entities.title ?? 'New Daily Habit';
    final frequency = entities.frequency ?? 'DAILY';

    final newHabit = Habit(
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      frequency: frequency,
      streakDay: 0,
      isCompleted: false,
    );

    provider.addHabit(newHabit);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '✨ I created your new habit: **"$title"** ($frequency). Consistency is key!',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createHabit,
      cardData: ActionCardData(
        type: ActionCardType.habitList,
        title: title,
        subtitle: '$frequency • 0 Day Streak',
        items: [
          ActionCardItem(
            id: newHabit.id,
            title: title,
            subtitle: '$frequency • Tap to mark done',
            icon: Icons.repeat_rounded,
            iconColor: const Color(0xFF10B981),
          ),
        ],
      ),
      suggestionChips: ['Show my habits', 'What should I do now?'],
    );
  }

  static AssistantMessage _completeHabit(ExtractedEntities entities, AppProvider provider, {required bool isComplete}) {
    final query = (entities.title ?? '').toLowerCase().trim();
    final habits = provider.habits;

    if (habits.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You don\'t have any active habits yet. Would you like to create one?',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Create a reading habit', 'Create a gym habit'],
      );
    }

    Habit? matchedHabit;
    if (query.isNotEmpty) {
      for (final h in habits) {
        if (h.title.toLowerCase().contains(query)) {
          matchedHabit = h;
          break;
        }
      }
    }

    matchedHabit ??= habits.firstWhere(
      (h) => h.isCompleted != isComplete,
      orElse: () => habits.first,
    );

    if (matchedHabit.isCompleted != isComplete) {
      provider.toggleHabit(matchedHabit.id);
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: isComplete
          ? '🔥 Great streak! I marked **"${matchedHabit.title}"** as completed today (Streak: ${matchedHabit.streakDay} days).'
          : '↩️ I updated **"${matchedHabit.title}"** as incomplete.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: isComplete ? SmartIntent.completeHabit : SmartIntent.uncompleteHabit,
      cardData: ActionCardData(
        type: ActionCardType.habitList,
        title: matchedHabit.title,
        subtitle: '${matchedHabit.streakDay} Day Streak • ${isComplete ? "Completed" : "Pending"}',
        items: [
          ActionCardItem(
            id: matchedHabit.id,
            title: matchedHabit.title,
            subtitle: 'Streak: ${matchedHabit.streakDay} days',
            icon: isComplete ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            iconColor: const Color(0xFF10B981),
            isCompleted: isComplete,
          ),
        ],
      ),
      suggestionChips: ['Show my habits', 'What should I do now?'],
    );
  }

  static AssistantMessage _deleteHabit(ExtractedEntities entities, AppProvider provider) {
    final query = (entities.title ?? '').toLowerCase().trim();
    final habits = provider.habits;

    if (habits.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You have no habits to delete.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    Habit? matchedHabit;
    if (query.isNotEmpty) {
      for (final h in habits) {
        if (h.title.toLowerCase().contains(query)) {
          matchedHabit = h;
          break;
        }
      }
    }

    if (matchedHabit == null) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Which habit would you like to delete?',
        isUser: false,
        timestamp: DateTime.now(),
        cardData: ActionCardData(
          type: ActionCardType.habitList,
          title: 'Select Habit',
          items: habits.map((h) => ActionCardItem(
            id: h.id,
            title: h.title,
            icon: Icons.delete_outline_rounded,
            iconColor: Colors.redAccent,
          )).toList(),
        ),
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '⚠️ Are you sure you want to permanently delete the habit **"${matchedHabit.title}"**?',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.deleteHabit,
      cardData: ActionCardData(
        type: ActionCardType.confirmationPrompt,
        title: 'Delete Habit',
        subtitle: matchedHabit.title,
        actions: [
          ActionButton(
            label: 'Confirm Delete',
            isDestructive: true,
            commandPayload: 'CONFIRM_DELETE_HABIT_${matchedHabit.id}',
          ),
          ActionButton(
            label: 'Cancel',
            isPrimary: false,
            commandPayload: 'CANCEL_ACTION',
          ),
        ],
      ),
    );
  }

  static AssistantMessage _getHabitStreak(AppProvider provider) {
    final habits = provider.habits;
    if (habits.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You haven\'t started any habits yet. Start a daily routine today!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Create a reading habit', 'Create a workout habit'],
      );
    }

    final totalStreak = habits.fold<int>(0, (sum, h) => sum + h.streakDay);
    final topHabit = habits.reduce((a, b) => a.streakDay > b.streakDay ? a : b);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🔥 Your longest active habit streak is **${topHabit.streakDay} days** on **"${topHabit.title}"** (Total combined streaks: $totalStreak days).',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getHabitStreak,
      suggestionChips: ['Show my habits', 'What should I do now?'],
    );
  }

  static AssistantMessage _getPendingHabits(AppProvider provider) {
    final pending = provider.habits.where((h) => !h.isCompleted).toList();

    if (pending.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🌟 Amazing! You completed all your daily habits for today.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my tasks', 'Plan my day'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🌱 You have **${pending.length} remaining habit(s)** for today:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getPendingHabits,
      cardData: ActionCardData(
        type: ActionCardType.habitList,
        title: 'Remaining Daily Habits',
        items: pending.map((h) => ActionCardItem(
          id: h.id,
          title: h.title,
          subtitle: '${h.frequency} • Streak: ${h.streakDay} days',
          icon: Icons.circle_outlined,
          iconColor: const Color(0xFF10B981),
        )).toList(),
      ),
      suggestionChips: ['Mark reading completed', 'What should I do now?'],
    );
  }

  static AssistantMessage _getAllHabits(AppProvider provider) {
    final habits = provider.habits;

    if (habits.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You have no habits tracked yet. Tell me a habit to create!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Create a reading habit', 'Create a workout habit'],
      );
    }

    final completedCount = habits.where((h) => h.isCompleted).length;

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🌱 Here are your habits ($completedCount/${habits.length} done today):',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getHabits,
      cardData: ActionCardData(
        type: ActionCardType.habitList,
        title: 'Daily Habits',
        subtitle: '$completedCount of ${habits.length} completed',
        items: habits.map((h) => ActionCardItem(
          id: h.id,
          title: h.title,
          subtitle: '${h.frequency} • Streak: ${h.streakDay} days',
          icon: h.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          iconColor: const Color(0xFF10B981),
          isCompleted: h.isCompleted,
        )).toList(),
      ),
      suggestionChips: ['Mark reading completed', 'What should I do now?'],
    );
  }
}
