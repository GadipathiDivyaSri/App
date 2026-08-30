import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class JournalRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
    String? rawInput,
  }) {
    switch (intent) {
      case SmartIntent.createJournalEntry:
        return _createJournalEntry(entities, provider, rawInput);
      case SmartIntent.searchJournal:
        return _searchJournal(entities, provider);
      case SmartIntent.getJournalEntries:
      default:
        return _getJournalEntries(provider);
    }
  }

  static AssistantMessage _createJournalEntry(ExtractedEntities entities, AppProvider provider, String? rawInput) {
    final title = entities.title ?? 'Daily Reflections & Focus';
    final content = rawInput ?? 'Captured via Wrindha Smart Assistant.';
    final mood = entities.mood ?? 'Productive';

    final newEntry = JournalEntry(
      id: 'j_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      date: DateTime.now(),
      mood: mood,
      tags: ['Assistant', mood],
    );

    provider.addJournalEntry(newEntry);

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📝 Saved private journal entry: **"$title"** (Mood: **$mood**).',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createJournalEntry,
      suggestionChips: ['Show my journal entries', 'What should I do now?'],
    );
  }

  static AssistantMessage _searchJournal(ExtractedEntities entities, AppProvider provider) {
    final query = (entities.title ?? '').toLowerCase().trim();
    final entries = provider.journalEntries;

    final matches = entries.where((j) =>
      j.title.toLowerCase().contains(query) ||
      j.content.toLowerCase().contains(query) ||
      j.tags.any((t) => t.toLowerCase().contains(query))
    ).toList();

    if (matches.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'No journal reflections found matching "$query".',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my journal entries', 'Write in my journal'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🔍 Found **${matches.length} matching journal entry(ies)**:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.searchJournal,
      cardData: ActionCardData(
        type: ActionCardType.taskList,
        title: 'Journal Results',
        items: matches.map((m) => ActionCardItem(
          id: m.id,
          title: m.title,
          subtitle: '${m.mood} • ${m.date.day}/${m.date.month}',
          icon: Icons.auto_stories_rounded,
          iconColor: const Color(0xFF0D5CE5),
        )).toList(),
      ),
      suggestionChips: ['Show my journal entries'],
    );
  }

  static AssistantMessage _getJournalEntries(AppProvider provider) {
    final entries = provider.journalEntries;
    if (entries.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Your journal is empty. Tell me how your study day went to log your first thought!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Today was very productive'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📖 Here are your recent journal entries (${entries.length} total):',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getJournalEntries,
      cardData: ActionCardData(
        type: ActionCardType.taskList,
        title: 'Personal Journal',
        items: entries.take(4).map((e) => ActionCardItem(
          id: e.id,
          title: e.title,
          subtitle: '${e.mood} • ${e.date.day}/${e.date.month}',
          icon: Icons.history_edu_rounded,
          iconColor: const Color(0xFF0D5CE5),
        )).toList(),
      ),
      suggestionChips: ['Today was very productive', 'Plan my day'],
    );
  }
}
