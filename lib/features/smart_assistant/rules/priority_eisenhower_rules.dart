import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class PriorityEisenhowerRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    switch (intent) {
      case SmartIntent.getHighestPriority:
        return _getHighestPriority(provider);
      case SmartIntent.getDoNowTasks:
        return _getDoNowTasks(provider);
      case SmartIntent.prioritizeTasks:
        return _prioritizeTasks(provider);
      case SmartIntent.getPriorityMatrix:
      case SmartIntent.getEisenhowerMatrix:
      default:
        return _getMatrix(provider);
    }
  }

  static AssistantMessage _getHighestPriority(AppProvider provider) {
    final pending = provider.tasks.where((t) => !t.isCompleted).toList();
    if (pending.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '✨ You currently have no pending tasks! Great job maintaining zero backlog.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Add a task', 'Plan my day'],
      );
    }

    // Sort by priority (1 is highest), then due date
    pending.sort((a, b) => a.priority.compareTo(b.priority));
    final top = pending.first;

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🔥 **Your Highest Priority Task**:\n**"${top.title}"** (${top.category})\nDue: **${top.dueDateLabel}** • Priority: **High / Urgent**',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getHighestPriority,
      cardData: ActionCardData(
        type: ActionCardType.singleTask,
        title: top.title,
        subtitle: '${top.category} • Priority 1 (Urgent & Important)',
        items: [
          ActionCardItem(
            id: top.id,
            title: top.title,
            subtitle: 'Due: ${top.dueDateLabel}',
            icon: Icons.priority_high_rounded,
            iconColor: Colors.redAccent,
          ),
        ],
        actions: [
          ActionButton(
            label: 'Start Focus Session',
            icon: Icons.play_arrow_rounded,
            commandPayload: 'START_FOCUS_${top.id}',
          ),
        ],
      ),
      suggestionChips: ['Mark task completed', 'What should I do now?'],
    );
  }

  static AssistantMessage _getDoNowTasks(AppProvider provider) {
    final doNow = provider.tasks.where((t) => !t.isCompleted && t.priority == 1).toList();

    if (doNow.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '⚡ No urgent "Do Now" (Q1) tasks! You are on top of your deadlines.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my priority matrix', 'Plan my day'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '⚡ **Eisenhower Q1 (Urgent + Important - Do Now)**:\nYou have **${doNow.length} critical task(s)** requiring immediate focus:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getDoNowTasks,
      cardData: ActionCardData(
        type: ActionCardType.taskList,
        title: 'Q1: Do Now Tasks',
        subtitle: '${doNow.length} urgent & important tasks',
        items: doNow.map((t) => ActionCardItem(
          id: t.id,
          title: t.title,
          subtitle: '${t.category} • Due ${t.dueDateLabel}',
          icon: Icons.flash_on_rounded,
          iconColor: Colors.amber,
        )).toList(),
      ),
      suggestionChips: ['What should I do now?', 'Mark task completed'],
    );
  }

  static AssistantMessage _prioritizeTasks(AppProvider provider) {
    final tasks = provider.tasks.where((t) => !t.isCompleted).toList();
    if (tasks.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You have no active tasks to prioritize.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // Auto-prioritize: items due today get P1, tomorrow P2, later P3
    for (final t in tasks) {
      if (t.dueDateLabel.toLowerCase().contains('today')) {
        t.priority = 1;
      } else if (t.dueDateLabel.toLowerCase().contains('tomorrow')) {
        t.priority = 2;
      } else {
        t.priority = 3;
      }
    }
    provider.notifyListeners();

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 **Tasks Auto-Prioritized**:\n• Due Today → **Priority 1 (Do Now)**\n• Due Tomorrow → **Priority 2 (Schedule)**\n• Later → **Priority 3 (Delegate/Batch)**',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.prioritizeTasks,
      suggestionChips: ['Show my priority matrix', 'What should I do now?'],
    );
  }

  static AssistantMessage _getMatrix(AppProvider provider) {
    final pending = provider.tasks.where((t) => !t.isCompleted).toList();
    final q1 = pending.where((t) => t.priority == 1).length;
    final q2 = pending.where((t) => t.priority == 2).length;
    final q3 = pending.where((t) => t.priority == 3).length;

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📊 **Eisenhower Priority Matrix**:\n• 🔴 **Q1 (Do Now)**: $q1 tasks\n• 🔵 **Q2 (Schedule)**: $q2 tasks\n• 🟡 **Q3 (Delegate/Batch)**: $q3 tasks\n• 🟢 **Q4 (Eliminate)**: 0 tasks',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getPriorityMatrix,
      cardData: ActionCardData(
        type: ActionCardType.taskList,
        title: 'Priority Quadrants',
        subtitle: '${pending.length} pending items categorized',
        items: pending.take(4).map((t) => ActionCardItem(
          id: t.id,
          title: t.title,
          subtitle: 'Q${t.priority} • ${t.dueDateLabel}',
          icon: Icons.dashboard_customize_rounded,
          iconColor: t.priority == 1 ? Colors.redAccent : (t.priority == 2 ? const Color(0xFF0D5CE5) : Colors.amber),
        )).toList(),
      ),
      suggestionChips: ['What should I do now?', 'What is my highest priority?'],
    );
  }
}
