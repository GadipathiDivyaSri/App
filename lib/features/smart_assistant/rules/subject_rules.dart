import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class SubjectRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    switch (intent) {
      case SmartIntent.createSubject:
        return _createSubject(entities, provider);
      case SmartIntent.createTopic:
        return _createTopic(entities, provider);
      case SmartIntent.completeTopic:
        return _completeTopic(entities, provider);
      case SmartIntent.getSubjectProgress:
        return _getSubjectProgress(provider);
      case SmartIntent.recommendStudy:
        return _recommendStudy(provider);
      case SmartIntent.getSubjects:
      default:
        return _getSubjects(provider);
    }
  }

  static AssistantMessage _createSubject(ExtractedEntities entities, AppProvider provider) {
    if (!provider.canAddSubject) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🔒 Free plan limit reached (Max 2 subjects). Upgrade to Pro for unlimited academic subjects!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my subjects', 'Study summary'],
      );
    }

    final name = entities.title ?? 'New Subject';
    final newSub = StudySubject(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      code: name.length >= 3 ? name.substring(0, 3).toUpperCase() : 'SUB',
      colorHex: 0xFF0D5CE5,
      progress: 0.0,
    );

    provider.addSubject(newSub);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📚 Added academic subject: **"$name"** (${newSub.code}).',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createSubject,
      suggestionChips: ['Add Calculus to Mathematics', 'Show my subjects'],
    );
  }

  static AssistantMessage _createTopic(ExtractedEntities entities, AppProvider provider) {
    final subjects = provider.subjects;
    if (subjects.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Please add a subject first before creating topics.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Add Mathematics as a subject'],
      );
    }

    final targetSub = subjects.first;
    final topicTitle = entities.title ?? 'Chapter 1: Foundations';

    final newItem = StudyItem(
      id: 'st_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: targetSub.id,
      subjectName: targetSub.name,
      title: topicTitle,
      type: 'TASK',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      isCompleted: false,
    );

    provider.addStudyItem(newItem);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📖 Added topic **"$topicTitle"** under **${targetSub.name}**.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createTopic,
      suggestionChips: ['Study summary', 'What should I study now?'],
    );
  }

  static AssistantMessage _completeTopic(ExtractedEntities entities, AppProvider provider) {
    final items = provider.studyItems.where((i) => !i.isCompleted).toList();
    if (items.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'All study items and topics are currently completed! Great job.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    final target = items.first;
    provider.toggleStudyItem(target.id);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🎉 Topic **"${target.title}"** marked completed! Updated syllabus progress for **${target.subjectName}**.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.completeTopic,
      suggestionChips: ['What should I study now?', 'Study summary'],
    );
  }

  static AssistantMessage _getSubjectProgress(AppProvider provider) {
    final subjects = provider.subjects;
    if (subjects.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You have no subjects registered in your academic planner.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Add Mathematics as a subject'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📊 **Academic Progress Breakdown**:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getSubjectProgress,
      cardData: ActionCardData(
        type: ActionCardType.subjectProgress,
        title: 'Subject Progress',
        subtitle: '${subjects.length} subjects enrolled',
        items: subjects.map((s) => ActionCardItem(
          id: s.id,
          title: s.name,
          subtitle: '${(s.progress * 100).round()}% Completed',
          trailingText: '${(s.progress * 100).round()}%',
          icon: Icons.menu_book_rounded,
          iconColor: Color(s.colorHex),
        )).toList(),
      ),
      suggestionChips: ['What should I study now?', 'Show my tasks'],
    );
  }

  static AssistantMessage _recommendStudy(AppProvider provider) {
    final subjects = provider.subjects;
    if (subjects.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Add your subjects to receive tailored study recommendations!',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // Recommend subject with lowest progress
    final lowest = subjects.reduce((a, b) => a.progress < b.progress ? a : b);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '💡 **Recommended Study Focus**: **${lowest.name}**\nYour progress is currently at **${(lowest.progress * 100).round()}%**. A 45-minute deep focus session will boost your retention.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.recommendStudy,
      suggestionChips: ['Start Focus session', 'Show my tasks'],
    );
  }

  static AssistantMessage _getSubjects(AppProvider provider) {
    final subjects = provider.subjects;
    if (subjects.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'No subjects configured yet. Tell me a subject name to add!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Add Physics as a subject'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📚 Here are your academic subjects:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getSubjects,
      cardData: ActionCardData(
        type: ActionCardType.subjectProgress,
        title: 'Academic Subjects',
        items: subjects.map((s) => ActionCardItem(
          id: s.id,
          title: s.name,
          subtitle: '${s.code} • ${(s.progress * 100).round()}% progress',
          icon: Icons.book_rounded,
          iconColor: Color(s.colorHex),
        )).toList(),
      ),
      suggestionChips: ['What should I study now?', 'Study summary'],
    );
  }
}
