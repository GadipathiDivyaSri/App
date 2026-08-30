import 'package:flutter/material.dart';
import '../../providers/app_provider.dart';
import 'assistant_response.dart';
import 'command_models.dart';
import 'entity_extractor.dart';
import 'intent_detector.dart';

class SmartAssistantService {
  /// Process raw user message and execute corresponding rules
  static List<AssistantMessage> processMessage({
    required String userText,
    required AppProvider provider,
    ConversationContext? currentContext,
  }) {
    final raw = userText.trim();
    if (raw.isEmpty) return [];

    // Check if handling multi-turn follow-up context
    if (currentContext != null) {
      final normalized = IntentDetector.normalize(raw);
      final entities = EntityExtractor.extract(rawText: raw, normalizedText: normalized);

      // Merge with partial entities
      final merged = currentContext.partialEntities.copyWith(
        title: entities.title ?? currentContext.partialEntities.title,
        date: entities.date ?? currentContext.partialEntities.date,
        dateLabel: entities.dateLabel ?? currentContext.partialEntities.dateLabel,
        time: entities.time ?? currentContext.partialEntities.time,
        timeString: entities.timeString ?? currentContext.partialEntities.timeString,
        amount: entities.amount ?? currentContext.partialEntities.amount,
        category: entities.category ?? currentContext.partialEntities.category,
      );

      final response = AssistantResponseBuilder.build(
        intent: currentContext.pendingIntent,
        entities: merged,
        provider: provider,
        rawInput: raw,
      );
      return [response];
    }

    // Multi-action command splitter
    final commandChunks = IntentDetector.splitMultiCommands(raw);
    final results = <AssistantMessage>[];

    for (final chunk in commandChunks) {
      final normalized = IntentDetector.normalize(chunk);
      final intent = IntentDetector.detectIntent(normalized);
      final entities = EntityExtractor.extract(rawText: chunk, normalizedText: normalized);

      final message = AssistantResponseBuilder.build(
        intent: intent,
        entities: entities,
        provider: provider,
        rawInput: chunk,
      );
      results.add(message);
    }

    return results;
  }

  /// Process action button clicks
  static AssistantMessage processPayload({
    required String payload,
    required AppProvider provider,
  }) {
    return AssistantResponseBuilder.handlePayload(payload, provider);
  }
}
