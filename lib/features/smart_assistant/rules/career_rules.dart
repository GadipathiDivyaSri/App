import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class CareerRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    switch (intent) {
      case SmartIntent.createCareerMilestone:
        return _createMilestone(entities, provider);
      case SmartIntent.completeCareerMilestone:
        return _completeMilestone(entities, provider);
      case SmartIntent.nextCareerAction:
        return _nextCareerAction(provider);
      case SmartIntent.getCareerRoadmap:
      default:
        return _getRoadmap(provider);
    }
  }

  static AssistantMessage _createMilestone(ExtractedEntities entities, AppProvider provider) {
    final title = entities.title ?? 'New Career Certification';
    final section = entities.category ?? 'SKILLS';

    final node = CareerRoadmapNode(
      id: 'cr_${DateTime.now().millisecondsSinceEpoch}',
      section: section,
      title: title,
      description: 'Milestone target',
      status: 'PLANNED',
      order: provider.careerNodes.length + 1,
    );
    provider.addCareerNode(node);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🚀 Added Career Milestone: **"$title"** under **$section**.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createCareerMilestone,
      suggestionChips: ['Show my career roadmap', 'What\'s my next career step?'],
    );
  }

  static AssistantMessage _completeMilestone(ExtractedEntities entities, AppProvider provider) {
    final query = (entities.title ?? '').toLowerCase().trim();
    final nodes = provider.careerNodes;

    CareerRoadmapNode? matched;
    if (query.isNotEmpty) {
      for (final n in nodes) {
        if (n.title.toLowerCase().contains(query)) {
          matched = n;
          break;
        }
      }
    }

    matched ??= nodes.firstWhere((n) => n.status != 'COMPLETED', orElse: () => nodes.first);
    matched.status = 'COMPLETED';
    provider.notifyListeners();

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎉 Milestone achieved! Marked **"${matched.title}"** as completed on your Career Roadmap.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.completeCareerMilestone,
      suggestionChips: ['What\'s my next career step?', 'Show my career roadmap'],
    );
  }

  static AssistantMessage _nextCareerAction(AppProvider provider) {
    final active = provider.careerNodes.where((n) => n.status == 'IN_PROGRESS' || n.status == 'PLANNED').toList();
    if (active.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'All roadmap stages completed! Time to establish new horizon objectives.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    final top = active.first;
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🚀 **Next Career Step**: **"${top.title}"**\nSection: **${top.section}**\n${top.description.isNotEmpty ? top.description : "Focus on consistent daily progression."}',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.nextCareerAction,
      suggestionChips: ['Mark milestone completed', 'Show my career roadmap'],
    );
  }

  static AssistantMessage _getRoadmap(AppProvider provider) {
    final nodes = provider.careerNodes;
    final completed = nodes.where((n) => n.status == 'COMPLETED').length;

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🚀 **Career & Growth Roadmap** ($completed/${nodes.length} stages reached):',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getCareerRoadmap,
      cardData: ActionCardData(
        type: ActionCardType.goalMeter,
        title: 'Career Trajectory',
        subtitle: '$completed of ${nodes.length} milestones complete',
        items: nodes.map((n) => ActionCardItem(
          id: n.id,
          title: n.title,
          subtitle: '${n.section} • ${n.status}',
          icon: n.status == 'COMPLETED' ? Icons.check_circle_rounded : Icons.timeline_rounded,
          iconColor: n.status == 'COMPLETED' ? const Color(0xFF10B981) : const Color(0xFF0D5CE5),
        )).toList(),
      ),
      suggestionChips: ['What\'s my next career step?', 'Plan my day'],
    );
  }
}
