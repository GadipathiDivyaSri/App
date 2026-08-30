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

    // Add as a high priority roadmap/goal node
    final newNode = CareerRoadmapNode(
      id: 'cr_${DateTime.now().millisecondsSinceEpoch}',
      section: 'GOAL',
      title: title,
      description: 'Goal in $category',
      status: 'IN_PROGRESS',
      order: provider.careerNodes.length + 1,
    );
    provider.addCareerNode(newNode);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 Created goal: **"$title"**. It has been linked to your academic & career pyramid.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createGoal,
      cardData: ActionCardData(
        type: ActionCardType.goalMeter,
        title: title,
        subtitle: 'Status: In Progress • Tier 1 Goal',
        items: [
          ActionCardItem(
            id: newNode.id,
            title: title,
            subtitle: 'Goal • In Progress',
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF0D5CE5),
          ),
        ],
      ),
      suggestionChips: ['What should I do for my goal?', 'Show my goals'],
    );
  }

  static AssistantMessage _completeGoal(ExtractedEntities entities, AppProvider provider) {
    final nodes = provider.careerNodes.where((n) => n.section == 'GOAL').toList();
    if (nodes.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You have no active goals to mark completed.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    final target = nodes.first;
    target.status = 'COMPLETED';
    provider.notifyListeners();

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
    final nodes = provider.careerNodes;
    if (nodes.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You don\'t have any goals set yet. Tell me a goal to create!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Create a goal to finish my syllabus', 'Plan my day'],
      );
    }

    final completed = nodes.where((n) => n.status == 'COMPLETED').length;
    final inProgress = nodes.where((n) => n.status == 'IN_PROGRESS').length;
    final percent = ((completed / nodes.length) * 100).round();

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 **Goal Pyramid Progress**:\n• Total Milestones: **${nodes.length}**\n• Completed: **$completed** ($percent%)\n• Active in progress: **$inProgress**',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getGoalProgress,
      cardData: ActionCardData(
        type: ActionCardType.goalMeter,
        title: '$percent% Goals Completed',
        subtitle: '$completed of ${nodes.length} targets achieved',
        items: nodes.map((n) => ActionCardItem(
          id: n.id,
          title: n.title,
          subtitle: '${n.section} • ${n.status}',
          icon: n.status == 'COMPLETED' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          iconColor: n.status == 'COMPLETED' ? const Color(0xFF10B981) : const Color(0xFF0D5CE5),
        )).toList(),
      ),
      suggestionChips: ['What should I do for my goal?', 'What should I do now?'],
    );
  }

  static AssistantMessage _nextGoalAction(AppProvider provider) {
    final pendingNodes = provider.careerNodes.where((n) => n.status != 'COMPLETED').toList();
    if (pendingNodes.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🎉 You have completed all existing roadmap goals! Ready to add a new ambitious target?',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    final topNode = pendingNodes.first;
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎯 **Next Recommended Goal Action**:\nFocus on **"${topNode.title}"** (${topNode.description.isNotEmpty ? topNode.description : topNode.section}).',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.nextGoalAction,
      suggestionChips: ['Add a task for this goal', 'Show my tasks'],
    );
  }

  static AssistantMessage _getAllGoals(AppProvider provider) {
    final nodes = provider.careerNodes;
    if (nodes.isEmpty) {
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
      text: '🎯 Here is your active Goal & Milestone Roadmap:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getGoals,
      cardData: ActionCardData(
        type: ActionCardType.goalMeter,
        title: 'Roadmap & Goals',
        subtitle: '${nodes.length} milestones tracked',
        items: nodes.map((n) => ActionCardItem(
          id: n.id,
          title: n.title,
          subtitle: '${n.section} • ${n.status}',
          icon: n.status == 'COMPLETED' ? Icons.check_circle_rounded : Icons.flag_rounded,
          iconColor: n.status == 'COMPLETED' ? const Color(0xFF10B981) : const Color(0xFF0D5CE5),
        )).toList(),
      ),
      suggestionChips: ['What should I do for my goal?', 'What should I do now?'],
    );
  }
}
