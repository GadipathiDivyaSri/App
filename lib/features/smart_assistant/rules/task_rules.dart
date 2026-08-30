import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class TaskRules {
  /// Handle all task-related intents
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    switch (intent) {
      case SmartIntent.createTask:
        return _createTask(entities, provider);
      case SmartIntent.completeTask:
        return _completeTask(entities, provider);
      case SmartIntent.deleteTask:
        return _deleteTask(entities, provider);
      case SmartIntent.rescheduleTask:
        return _rescheduleTask(entities, provider);
      case SmartIntent.getPendingTasks:
        return _getPendingTasks(provider);
      case SmartIntent.getOverdueTasks:
        return _getOverdueTasks(provider);
      case SmartIntent.getTasks:
      default:
        return _getAllTasks(provider);
    }
  }

  static AssistantMessage _createTask(ExtractedEntities entities, AppProvider provider) {
    final title = entities.title ?? 'New Study Task';
    final category = entities.category ?? 'Studies';
    final dateLabel = entities.dateLabel ?? 'Today';
    final priority = entities.priority ?? 1;

    provider.addTask(
      title,
      category,
      dateLabel,
      priority: priority,
    );

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '✅ I added your task: **"$title"** scheduled for **$dateLabel** (Priority $priority).',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createTask,
      cardData: ActionCardData(
        type: ActionCardType.singleTask,
        title: title,
        subtitle: '$category • $dateLabel • ${priority == 1 ? "🔥 High Priority" : "Priority $priority"}',
        items: [
          ActionCardItem(
            id: 'item_1',
            title: title,
            subtitle: '$category • Due $dateLabel',
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF0D5CE5),
          ),
        ],
      ),
      suggestionChips: [
        'Show my tasks',
        'What should I do now?',
        'Plan my day',
      ],
    );
  }

  static AssistantMessage _completeTask(ExtractedEntities entities, AppProvider provider) {
    final query = (entities.title ?? '').toLowerCase().trim();
    final tasks = provider.tasks;

    if (tasks.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You don\'t have any active tasks yet. Would you like me to create one?',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Add a task to study physics', 'Plan my day'],
      );
    }

    Task? matchedTask;
    if (query.isNotEmpty) {
      // Find matching pending task
      for (final t in tasks) {
        if (t.title.toLowerCase().contains(query)) {
          matchedTask = t;
          break;
        }
      }
    }

    // Default to first pending task if query is generic
    matchedTask ??= tasks.firstWhere(
      (t) => !t.isCompleted,
      orElse: () => tasks.first,
    );

    if (!matchedTask.isCompleted) {
      provider.toggleTaskCompletion(matchedTask.id);
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎉 Awesome job! I marked **"${matchedTask.title}"** as completed.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.completeTask,
      cardData: ActionCardData(
        type: ActionCardType.singleTask,
        title: matchedTask.title,
        subtitle: 'Completed • Streak updated',
        items: [
          ActionCardItem(
            id: matchedTask.id,
            title: matchedTask.title,
            subtitle: 'Marked Completed',
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF10B981),
            isCompleted: true,
          ),
        ],
      ),
      suggestionChips: [
        'Show my tasks',
        'What should I do now?',
        'Show my progress',
      ],
    );
  }

  static AssistantMessage _deleteTask(ExtractedEntities entities, AppProvider provider) {
    final query = (entities.title ?? '').toLowerCase().trim();
    final tasks = provider.tasks;

    if (tasks.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You have no tasks to delete.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    Task? matchedTask;
    if (query.isNotEmpty) {
      for (final t in tasks) {
        if (t.title.toLowerCase().contains(query)) {
          matchedTask = t;
          break;
        }
      }
    }

    if (matchedTask == null) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'I couldn\'t find a task matching "$query". Which task would you like to delete?',
        isUser: false,
        timestamp: DateTime.now(),
        cardData: ActionCardData(
          type: ActionCardType.taskList,
          title: 'Select a task to delete',
          items: tasks.take(4).map((t) => ActionCardItem(
            id: t.id,
            title: t.title,
            subtitle: t.category,
            icon: Icons.delete_outline_rounded,
            iconColor: Colors.redAccent,
          )).toList(),
        ),
      );
    }

    // Require confirmation for destructive action
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '⚠️ Are you sure you want to permanently delete **"${matchedTask.title}"**?',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.deleteTask,
      cardData: ActionCardData(
        type: ActionCardType.confirmationPrompt,
        title: 'Delete Task',
        subtitle: matchedTask.title,
        actions: [
          ActionButton(
            label: 'Confirm Delete',
            isDestructive: true,
            commandPayload: 'CONFIRM_DELETE_TASK_${matchedTask.id}',
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

  static AssistantMessage _rescheduleTask(ExtractedEntities entities, AppProvider provider) {
    final query = (entities.title ?? '').toLowerCase().trim();
    final newDateLabel = entities.dateLabel ?? 'Tomorrow';
    final tasks = provider.tasks;

    Task? matchedTask;
    if (query.isNotEmpty) {
      for (final t in tasks) {
        if (t.title.toLowerCase().contains(query)) {
          matchedTask = t;
          break;
        }
      }
    }

    matchedTask ??= tasks.firstWhere(
      (t) => !t.isCompleted,
      orElse: () => tasks.first,
    );

    matchedTask.dueDateLabel = newDateLabel;
    if (entities.date != null) {
      matchedTask.dueDate = entities.date!;
    }
    provider.notifyListeners();

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🗓️ I moved **"${matchedTask.title}"** to **$newDateLabel**.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.rescheduleTask,
      suggestionChips: ['Show my tasks', 'Plan my day'],
    );
  }

  static AssistantMessage _getPendingTasks(AppProvider provider) {
    final pending = provider.tasks.where((t) => !t.isCompleted).toList();

    if (pending.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '✨ You have no pending tasks! Everything is completed.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Add a task', 'Plan my day', 'Show my habits'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📋 You have **${pending.length} pending task(s)**:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getPendingTasks,
      cardData: ActionCardData(
        type: ActionCardType.taskList,
        title: 'Pending Tasks',
        subtitle: '${pending.length} tasks remaining',
        items: pending.map((t) => ActionCardItem(
          id: t.id,
          title: t.title,
          subtitle: '${t.category} • Due ${t.dueDateLabel}',
          icon: Icons.circle_outlined,
          iconColor: const Color(0xFF0D5CE5),
        )).toList(),
      ),
      suggestionChips: [
        'What should I do now?',
        'Mark task completed',
        'Plan my day',
      ],
    );
  }

  static AssistantMessage _getOverdueTasks(AppProvider provider) {
    final now = DateTime.now();
    final overdue = provider.tasks.where((t) => !t.isCompleted && t.dueDate.isBefore(now) && t.dueDateLabel != 'Today').toList();

    if (overdue.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '👍 Great news! You have no overdue tasks.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['What should I do now?', 'Show my tasks'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '⚠️ You have **${overdue.length} overdue task(s)**:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getOverdueTasks,
      cardData: ActionCardData(
        type: ActionCardType.taskList,
        title: 'Overdue Tasks',
        subtitle: 'Needs immediate attention',
        items: overdue.map((t) => ActionCardItem(
          id: t.id,
          title: t.title,
          subtitle: 'Overdue • ${t.category}',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.redAccent,
        )).toList(),
      ),
      suggestionChips: [
        'Reschedule overdue tasks',
        'What should I do now?',
      ],
    );
  }

  static AssistantMessage _getAllTasks(AppProvider provider) {
    final tasks = provider.tasks;

    if (tasks.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Your task list is empty. Tell me what you\'d like to work on and I\'ll add it!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Add math homework', 'Plan my day'],
      );
    }

    final completedCount = tasks.where((t) => t.isCompleted).length;

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📋 Here are your tasks ($completedCount/${tasks.length} completed):',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getTasks,
      cardData: ActionCardData(
        type: ActionCardType.taskList,
        title: 'My Tasks',
        subtitle: '$completedCount of ${tasks.length} completed',
        items: tasks.map((t) => ActionCardItem(
          id: t.id,
          title: t.title,
          subtitle: '${t.category} • Due ${t.dueDateLabel}',
          icon: t.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
          iconColor: t.isCompleted ? const Color(0xFF10B981) : const Color(0xFF0D5CE5),
          isCompleted: t.isCompleted,
        )).toList(),
      ),
      suggestionChips: [
        'What should I do now?',
        'Mark task completed',
        'Show my habits',
      ],
    );
  }
}
