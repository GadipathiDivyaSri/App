import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class CalendarRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    switch (intent) {
      case SmartIntent.createCalendarEvent:
        return _createEvent(entities, provider);
      case SmartIntent.deleteCalendarEvent:
        return _deleteEvent(entities, provider);
      case SmartIntent.getCalendarEvents:
      default:
        return _getEvents(provider);
    }
  }

  static AssistantMessage _createEvent(ExtractedEntities entities, AppProvider provider) {
    final title = entities.title ?? 'Focus Meeting';
    final date = entities.date ?? DateTime.now();
    final startTime = entities.time ?? const TimeOfDay(hour: 15, minute: 0);
    final endTime = TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);

    provider.addCalendarEvent(
      title,
      'Scheduled via Smart Assistant',
      date,
      startTime,
      endTime,
      entities.location ?? 'Workspace',
      'Meeting',
    );

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📅 Added event: **"$title"** on **${date.day}/${date.month}** at **${entities.timeString ?? "03:00 PM"}**.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createCalendarEvent,
      cardData: ActionCardData(
        type: ActionCardType.schedulePlan,
        title: title,
        subtitle: '${date.day}/${date.month} • ${entities.timeString ?? "03:00 PM"} - ${(startTime.hour + 1) % 24}:00',
        items: [
          ActionCardItem(
            id: 'ev_item',
            title: title,
            subtitle: 'Meeting • Workspace',
            icon: Icons.event_rounded,
            iconColor: const Color(0xFF0D5CE5),
          ),
        ],
      ),
      suggestionChips: ['What\'s on my calendar today?', 'Plan my day'],
    );
  }

  static AssistantMessage _deleteEvent(ExtractedEntities entities, AppProvider provider) {
    final events = provider.calendarEvents;
    if (events.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'You have no scheduled calendar events to delete.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    final target = events.first;
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '⚠️ Delete event **"${target.title}"**?',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.deleteCalendarEvent,
      cardData: ActionCardData(
        type: ActionCardType.confirmationPrompt,
        title: 'Delete Event',
        subtitle: target.title,
        actions: [
          ActionButton(
            label: 'Confirm Delete',
            isDestructive: true,
            commandPayload: 'CONFIRM_DELETE_EVENT_${target.id}',
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

  static AssistantMessage _getEvents(AppProvider provider) {
    final events = provider.calendarEvents;
    if (events.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '📅 Your calendar is clear for today! No upcoming events or meetings.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Add a meeting tomorrow at 3 PM', 'Plan my day'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📅 You have **${events.length} event(s)** scheduled:',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getCalendarEvents,
      cardData: ActionCardData(
        type: ActionCardType.schedulePlan,
        title: 'Calendar Schedule',
        subtitle: '${events.length} upcoming events',
        items: events.map((e) => ActionCardItem(
          id: e.id,
          title: e.title,
          subtitle: '${e.startTime.hour}:${e.startTime.minute.toString().padLeft(2, '0')} • ${e.location}',
          icon: Icons.event_available_rounded,
          iconColor: const Color(0xFF0D5CE5),
        )).toList(),
      ),
      suggestionChips: ['When am I free?', 'Plan my day'],
    );
  }
}
