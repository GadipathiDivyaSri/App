import 'package:flutter/material.dart';
import '../../../providers/app_provider.dart';
import '../command_models.dart';

class TimetableRules {
  static AssistantMessage handle({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
  }) {
    switch (intent) {
      case SmartIntent.createTimetableEntry:
        return _createEntry(entities, provider);
      case SmartIntent.findFreeTime:
        return _findFreeTime(provider);
      case SmartIntent.getTimetable:
      default:
        return _getTimetable(provider);
    }
  }

  static AssistantMessage _createEntry(ExtractedEntities entities, AppProvider provider) {
    final title = entities.title ?? 'Lecture';
    final date = entities.date ?? DateTime.now();
    final time = entities.time ?? const TimeOfDay(hour: 10, minute: 0);

    provider.addCalendarEvent(
      title,
      'Class Timetable',
      date,
      time,
      TimeOfDay(hour: (time.hour + 1) % 24, minute: time.minute),
      'Room 101',
      'Task',
    );

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '🕒 Scheduled timetable block: **"$title"** on **${entities.dateLabel ?? "Monday"}** at **${entities.timeString ?? "10:00 AM"}**.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.createTimetableEntry,
      suggestionChips: ['What\'s my timetable today?', 'When am I free?'],
    );
  }

  static AssistantMessage _findFreeTime(AppProvider provider) {
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '⏱️ **Available Free Time Slots Today**:\n• **11:00 AM – 01:00 PM** (2 hrs deep work)\n• **03:30 PM – 05:00 PM** (1.5 hrs study slot)\n• **07:30 PM – 09:30 PM** (2 hrs evening review)\n\nTotal available study bandwidth: **5.5 hours**.',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.findFreeTime,
      cardData: ActionCardData(
        type: ActionCardType.schedulePlan,
        title: 'Available Study Slots',
        subtitle: '5.5 hrs total open time',
        items: [
          ActionCardItem(
            id: 'slot_1',
            title: '11:00 AM – 01:00 PM',
            subtitle: 'Morning Focus Slot (2 hours)',
            icon: Icons.hourglass_top_rounded,
            iconColor: const Color(0xFF10B981),
          ),
          ActionCardItem(
            id: 'slot_2',
            title: '03:30 PM – 05:00 PM',
            subtitle: 'Afternoon Study Slot (1.5 hours)',
            icon: Icons.hourglass_bottom_rounded,
            iconColor: const Color(0xFF10B981),
          ),
        ],
      ),
      suggestionChips: ['Plan my day', 'What should I do now?'],
    );
  }

  static AssistantMessage _getTimetable(AppProvider provider) {
    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: '📅 **Today\'s Academic Timetable**:\n• 09:00 AM – 10:30 AM: Computer Science (CS101)\n• 11:00 AM – 12:30 PM: Applied Mathematics\n• 02:00 PM – 03:30 PM: Systems Lab Session',
      isUser: false,
      timestamp: DateTime.now(),
      detectedIntent: SmartIntent.getTimetable,
      suggestionChips: ['When am I free?', 'Plan my day'],
    );
  }
}
