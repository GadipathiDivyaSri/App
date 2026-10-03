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

    // Add as a task in To-Do list
    final newTask = Task(
      id: generateUuidV4(),
      title: title,
      description: 'Goal in $category',
      category: category,
      priority: 'high',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      isCompleted: false,
    );
    provider.addTask(newTask);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 Goal added to your Tasks: **"$title"**.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createGoal,
      cardData: ActionCardData(
        type: ActionCardType.taskList,
        title: title,
        subtitle: 'Category: $category • High Priority',
        items: [
          ActionCardItem(
            id: newTask.id,
            title: title,
            subtitle: 'High Priority Task',
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF0D5CE5),
          ),
        ],
      ),
      suggestionChips: ['Show my tasks', 'Show career roadmap'],
    );
  }

  static AssistantMessage _completeGoal(ExtractedEntities entities, AppProvider provider) {
    final query = (entities.title ?? '').toLowerCase().trim();
    final tasks = provider.tasks;
    if (tasks.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You have no active tasks or goals to mark completed.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Create a task', 'Plan my day'],
      );
    }

    Task? target;
    if (query.isNotEmpty && query != 'untitled item') {
      for (final t in tasks) {
        final title = t.title.toLowerCase();
        if (title.contains(query) || query.contains(title)) {
          target = t;
          break;
        }
      }
    }

    target ??= tasks.firstWhere((t) => !t.isCompleted, orElse: () => tasks.first);
    provider.toggleTaskCompletion(target.id);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🏆 Congratulations! You accomplished your goal/task: **"${target.title}"**!',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.completeGoal,
      suggestionChips: ['Show my tasks', 'Create a new task'],
    );
  }

  static AssistantMessage _getGoalProgress(AppProvider provider) {
    final tasks = provider.tasks;
    if (tasks.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You don\'t have any tasks or goals set yet. Tell me a task to create!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Create a task to finish my syllabus', 'Plan my day'],
      );
    }

    final completed = tasks.where((t) => t.isCompleted).length;
    final percent = ((completed / tasks.length) * 100).round();

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 **Task & Goal Progress**:\n• Total Tasks: **${tasks.length}**\n• Completed: **$completed** ($percent%)',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getGoalProgress,
      suggestionChips: ['Show my tasks', 'What should I do now?'],
    );
  }

  static AssistantMessage _nextGoalAction(AppProvider provider) {
    final pendingTasks = provider.tasks.where((t) => !t.isCompleted).toList();
    if (pendingTasks.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🎉 You have completed all existing tasks and goals! Ready to add a new ambitious target?',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    final topTask = pendingTasks.first;
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 **Next Recommended Action**:\nFocus on **"${topTask.title}"** (${topTask.category}).',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.nextGoalAction,
      suggestionChips: ['Show my tasks', 'Show career roadmap'],
    );
  }

  static AssistantMessage _getAllGoals(AppProvider provider) {
    final tasks = provider.tasks;
    if (tasks.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You haven\'t set up any tasks or goals yet. Tell me a target to begin!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Create a task to finish my syllabus'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 Here are your active priority targets:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getGoals,
      suggestionChips: ['Show my tasks', 'What should I do now?'],
    );
  }
}
