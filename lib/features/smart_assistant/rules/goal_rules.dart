import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class GoalRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    switch (intent) {
      case SmartIntent.createGoal:
        return _createGoal(entities, provider);
      case SmartIntent.completeGoal:
        return _completeGoal(entities, provider);
      case SmartIntent.getGoalProgress:
        return _getGoalProgress(provider);
      case SmartIntent.nextGoalAction:
        return _nextGoalAction(provider);
      case SmartIntent.getGoals:
      default:
        return _getAllGoals(provider);
    }
  }

  static AssistantMessage _createGoal(ExtractedEntities entities, AppProvider provider) {
    final title = entities.title ?? 'Achieve Academic Excellence';
    final category = entities.category ?? 'Studies';

    // Add as a goal in Goal Pyramid
    final newGoal = Goal(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: 'Goal in $category',
      tier: 'short',
      isCompleted: false,
    );
    provider.addGoal(newGoal);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 Created goal: **"$title"**. It has been added to your Goal Pyramid.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createGoal,
      cardData: ActionCardData(
        type: ActionCardType.goalMeter,
        title: title,
        subtitle: 'Status: In Progress • Short Term Goal',
        items: [
          ActionCardItem(
            id: newGoal.id,
            title: title,
            subtitle: 'Goal • Short Term',
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF0D5CE5),
          ),
        ],
      ),
      suggestionChips: ['What should I do for my goal?', 'Show my goals'],
    );
  }

  static AssistantMessage _completeGoal(ExtractedEntities entities, AppProvider provider) {
    final query = (entities.title ?? '').toLowerCase().trim();
    final goals = provider.goals;
    if (goals.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You have no active goals to mark completed.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Create a goal to finish my syllabus', 'Plan my day'],
      );
    }

    Goal? target;
    if (query.isNotEmpty && query != 'untitled item') {
      for (final g in goals) {
        final title = g.title.toLowerCase();
        if (title.contains(query) || query.contains(title)) {
          target = g;
          break;
        }
      }
    }

    target ??= goals.firstWhere((g) => !g.isCompleted, orElse: () => goals.first);
    provider.toggleGoal(target.id);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🏆 Congratulations! You accomplished your goal: **"${target.title}"**!',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.completeGoal,
      suggestionChips: ['Show my progress', 'Create a new goal'],
    );
  }

  static AssistantMessage _getGoalProgress(AppProvider provider) {
    final goals = provider.goals;
    if (goals.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You don\'t have any goals set yet. Tell me a goal to create!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Create a goal to finish my syllabus', 'Plan my day'],
      );
    }

    final completed = goals.where((g) => g.isCompleted).length;
    final inProgress = goals.where((g) => !g.isCompleted).length;
    final percent = ((completed / goals.length) * 100).round();

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 **Goal Pyramid Progress**:\n• Total Goals: **${goals.length}**\n• Completed: **$completed** ($percent%)\n• Active in progress: **$inProgress**',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getGoalProgress,
      cardData: ActionCardData(
        type: ActionCardType.goalMeter,
        title: '$percent% Goals Completed',
        subtitle: '$completed of ${goals.length} targets achieved',
        items: goals.map((g) => ActionCardItem(
          id: g.id,
          title: g.title,
          subtitle: '${g.tier.toUpperCase()} • ${g.isCompleted ? "COMPLETED" : "IN_PROGRESS"}',
          icon: g.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          iconColor: g.isCompleted ? const Color(0xFF10B981) : const Color(0xFF0D5CE5),
        )).toList(),
      ),
      suggestionChips: ['What should I do for my goal?', 'What should I do now?'],
    );
  }

  static AssistantMessage _nextGoalAction(AppProvider provider) {
    final pendingGoals = provider.goals.where((g) => !g.isCompleted).toList();
    if (pendingGoals.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🎉 You have completed all existing goals! Ready to add a new ambitious target?',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    final topGoal = pendingGoals.first;
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 **Next Recommended Goal Action**:\nFocus on **"${topGoal.title}"** (${topGoal.description.isNotEmpty ? topGoal.description : topGoal.tier.toUpperCase()}).',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.nextGoalAction,
      suggestionChips: ['Add a task for this goal', 'Show my tasks'],
    );
  }

  static AssistantMessage _getAllGoals(AppProvider provider) {
    final goals = provider.goals;
    if (goals.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You haven\'t set up your goals yet. Tell me a goal to begin!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Create a goal to finish my syllabus'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 Here is your active Goal Pyramid:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getGoals,
      cardData: ActionCardData(
        type: ActionCardType.goalMeter,
        title: 'Goal Pyramid',
        subtitle: '${goals.length} goals tracked',
        items: goals.map((g) => ActionCardItem(
          id: g.id,
          title: g.title,
          subtitle: '${g.tier.toUpperCase()} • ${g.isCompleted ? "COMPLETED" : "IN_PROGRESS"}',
          icon: g.isCompleted ? Icons.check_circle_rounded : Icons.flag_rounded,
          iconColor: g.isCompleted ? const Color(0xFF10B981) : const Color(0xFF0D5CE5),
        )).toList(),
      ),
      suggestionChips: ['What should I do for my goal?', 'What should I do now?'],
    );
  }
}
