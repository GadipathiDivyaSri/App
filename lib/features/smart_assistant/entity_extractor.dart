import 'package:flutter/material.dart';
import 'command_models.dart';

class EntityExtractor {
  /// Extract structured entities from normalized text and optional raw text
  static ExtractedEntities extract({
    required String rawText,
    required String normalizedText,
  }) {
    final dateResult = extractDate(normalizedText);
    final timeResult = extractTime(normalizedText);
    final amountResult = extractAmount(rawText);
    final priorityResult = extractPriority(normalizedText);
    final categoryResult = extractCategory(normalizedText);
    final frequencyResult = extractFrequency(normalizedText);
    final moodResult = extractMood(normalizedText);
    final titleResult = extractTitle(
      normalizedText: normalizedText,
      extractedDateWord: dateResult.matchedWord,
      extractedTimeWord: timeResult.matchedWord,
      extractedAmountWord: amountResult.matchedWord,
    );

    return ExtractedEntities(
      title: titleResult,
      category: categoryResult,
      date: dateResult.dateTime,
      dateLabel: dateResult.label,
      time: timeResult.timeOfDay,
      timeString: timeResult.formattedString,
      amount: amountResult.amount,
      priority: priorityResult,
      frequency: frequencyResult,
      mood: moodResult,
    );
  }

  // ---------------------------------------------------------------------------
  // Date Extraction
  // ---------------------------------------------------------------------------
  static DateParseResult extractDate(String text) {
    final now = DateTime.now();

    if (RegExp(r'\b(today|tonight)\b').hasMatch(text)) {
      return DateParseResult(
        dateTime: DateTime(now.year, now.month, now.day),
        label: 'Today',
        matchedWord: 'today',
      );
    }

    if (RegExp(r'\btomorrow\b').hasMatch(text)) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateParseResult(
        dateTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
        label: 'Tomorrow',
        matchedWord: 'tomorrow',
      );
    }

    if (RegExp(r'\byesterday\b').hasMatch(text)) {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateParseResult(
        dateTime: DateTime(yesterday.year, yesterday.month, yesterday.day),
        label: 'Yesterday',
        matchedWord: 'yesterday',
      );
    }

    if (RegExp(r'\b(this weekend|weekend)\b').hasMatch(text)) {
      final daysUntilSaturday = (DateTime.saturday - now.weekday + 7) % 7;
      final saturday = now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
      return DateParseResult(
        dateTime: DateTime(saturday.year, saturday.month, saturday.day),
        label: 'This Weekend',
        matchedWord: 'this weekend',
      );
    }

    // "in X days"
    final inDaysMatch = RegExp(r'\bin\s+(\d+)\s+days?\b').firstMatch(text);
    if (inDaysMatch != null) {
      final days = int.tryParse(inDaysMatch.group(1) ?? '1') ?? 1;
      final target = now.add(Duration(days: days));
      return DateParseResult(
        dateTime: DateTime(target.year, target.month, target.day),
        label: 'In $days days',
        matchedWord: inDaysMatch.group(0),
      );
    }

    // Days of the week
    final daysOfWeek = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    for (final entry in daysOfWeek.entries) {
      final dayName = entry.key;
      final targetWeekday = entry.value;

      if (RegExp('\\b(next\\s+$dayName|$dayName)\\b').hasMatch(text)) {
        var diff = targetWeekday - now.weekday;
        if (diff <= 0) diff += 7;
        final targetDate = now.add(Duration(days: diff));
        final capName = dayName[0].toUpperCase() + dayName.substring(1);
        return DateParseResult(
          dateTime: DateTime(targetDate.year, targetDate.month, targetDate.day),
          label: capName,
          matchedWord: dayName,
        );
      }
    }

    return DateParseResult(
      dateTime: DateTime(now.year, now.month, now.day),
      label: 'Today',
      matchedWord: null,
    );
  }

  // ---------------------------------------------------------------------------
  // Time Extraction
  // ---------------------------------------------------------------------------
  static TimeParseResult extractTime(String text) {
    // "at 7 PM", "7:30 pm", "at 10:00 AM", "7pm", "5 am"
    final timeMatch = RegExp(
      r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (timeMatch != null) {
      int hour = int.tryParse(timeMatch.group(1) ?? '0') ?? 0;
      final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final period = (timeMatch.group(3) ?? 'pm').toLowerCase();

      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      final formattedHour = (hour == 0 || hour == 12) ? 12 : hour % 12;
      final formattedMinute = minute.toString().padLeft(2, '0');
      final formattedPeriod = hour >= 12 ? 'PM' : 'AM';
      final formattedString = '$formattedHour:$formattedMinute $formattedPeriod';

      return TimeParseResult(
        timeOfDay: TimeOfDay(hour: hour, minute: minute),
        formattedString: formattedString,
        matchedWord: timeMatch.group(0),
      );
    }

    if (RegExp(r'\b(morning)\b').hasMatch(text)) {
      return TimeParseResult(
        timeOfDay: const TimeOfDay(hour: 9, minute: 0),
        formattedString: '09:00 AM',
        matchedWord: 'morning',
      );
    }

    if (RegExp(r'\b(afternoon)\b').hasMatch(text)) {
      return TimeParseResult(
        timeOfDay: const TimeOfDay(hour: 14, minute: 0),
        formattedString: '02:00 PM',
        matchedWord: 'afternoon',
      );
    }

    if (RegExp(r'\b(evening|tonight)\b').hasMatch(text)) {
      return TimeParseResult(
        timeOfDay: const TimeOfDay(hour: 19, minute: 0),
        formattedString: '07:00 PM',
        matchedWord: 'evening',
      );
    }

    return TimeParseResult(
      timeOfDay: const TimeOfDay(hour: 17, minute: 0),
      formattedString: '05:00 PM',
      matchedWord: null,
    );
  }

  // ---------------------------------------------------------------------------
  // Amount Extraction
  // ---------------------------------------------------------------------------
  static AmountParseResult extractAmount(String text) {
    // "₹250", "250 rupees", "rs. 500", "rs 1000", "spent 350"
    final amountMatch = RegExp(
      r'(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d{1,2})?)\s*(?:rupees|rs\.?|inr)?',
      caseSensitive: false,
    ).firstMatch(text);

    if (amountMatch != null) {
      final valueStr = amountMatch.group(1);
      if (valueStr != null) {
        final val = double.tryParse(valueStr);
        if (val != null && val > 0) {
          return AmountParseResult(
            amount: val,
            matchedWord: amountMatch.group(0),
          );
        }
      }
    }

    return AmountParseResult(amount: null, matchedWord: null);
  }

  // ---------------------------------------------------------------------------
  // Priority Extraction
  // ---------------------------------------------------------------------------
  static int extractPriority(String text) {
    if (RegExp(r'\b(high|urgent|important|p1|critical|highest)\b').hasMatch(text)) {
      return 1;
    }
    if (RegExp(r'\b(medium|schedule|p2|moderate|normal)\b').hasMatch(text)) {
      return 2;
    }
    if (RegExp(r'\b(low|delegate|eliminate|p3|minor)\b').hasMatch(text)) {
      return 3;
    }
    return 1;
  }

  // ---------------------------------------------------------------------------
  // Category Extraction
  // ---------------------------------------------------------------------------
  static String extractCategory(String text) {
    // Expenses
    if (RegExp(r'\b(food|dining|lunch|dinner|snack|coffee|tea|cafe|groceries)\b').hasMatch(text)) {
      return 'Food & Dining';
    }
    if (RegExp(r'\b(transport|bus|cab|uber|ola|petrol|fuel|auto|metro|train)\b').hasMatch(text)) {
      return 'Transportation';
    }
    if (RegExp(r'\b(book|books|course|tuition|exam fee|stationery|college|class|fees)\b').hasMatch(text)) {
      return 'Education';
    }
    if (RegExp(r'\b(movie|game|entertainment|ott|netflix|subscription|fun)\b').hasMatch(text)) {
      return 'Entertainment';
    }
    if (RegExp(r'\b(shopping|clothes|shoes|gadget|amazon|flipkart)\b').hasMatch(text)) {
      return 'Shopping';
    }
    if (RegExp(r'\b(health|medicine|doctor|pharmacy|gym)\b').hasMatch(text)) {
      return 'Health';
    }

    // Tasks & Goals
    if (RegExp(r'\b(math|physics|chemistry|biology|science|computer|history|syllabus|study|studies|homework|assignment|exam|quiz)\b').hasMatch(text)) {
      return 'Studies';
    }
    if (RegExp(r'\b(career|job|internship|resume|interview|project|coding|portfolio|certification|roadmap)\b').hasMatch(text)) {
      return 'Career Roadmap';
    }
    if (RegExp(r'\b(habit|meditation|reading|exercise|workout|sleep|water|growth|journal)\b').hasMatch(text)) {
      return 'Personal Growth';
    }

    return 'Studies';
  }

  // ---------------------------------------------------------------------------
  // Frequency Extraction
  // ---------------------------------------------------------------------------
  static String extractFrequency(String text) {
    if (RegExp(r'\b(weekly|once a week|every week)\b').hasMatch(text)) {
      return 'WEEKLY';
    }
    if (RegExp(r'\b(monthly|once a month)\b').hasMatch(text)) {
      return 'MONTHLY';
    }
    return 'DAILY';
  }

  // ---------------------------------------------------------------------------
  // Mood Extraction
  // ---------------------------------------------------------------------------
  static String extractMood(String text) {
    if (RegExp(r'\b(happy|great|excited|joy|awesome|wonderful)\b').hasMatch(text)) {
      return 'Happy';
    }
    if (RegExp(r'\b(productive|focused|efficient|accomplished|energized)\b').hasMatch(text)) {
      return 'Productive';
    }
    if (RegExp(r'\b(calm|peaceful|relaxed|serene)\b').hasMatch(text)) {
      return 'Calm';
    }
    if (RegExp(r'\b(stressed|tired|exhausted|anxious|overwhelmed|sad)\b').hasMatch(text)) {
      return 'Stressed';
    }
    return 'Reflective';
  }

  // ---------------------------------------------------------------------------
  // Clean Title Extraction
  // ---------------------------------------------------------------------------
  static String extractTitle({
    required String normalizedText,
    String? extractedDateWord,
    String? extractedTimeWord,
    String? extractedAmountWord,
  }) {
    var cleaned = normalizedText;

    // Remove intent trigger verbs
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(add|create|new|schedule|insert|set up|log|mark|complete|finish|done with|delete|remove|reschedule|move|put)\b'),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(a task to|a task|task|a habit to|a habit|habit|a goal to|a goal|goal|an expense for|an expense|expense|a meeting with|meeting|event)\b'),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(please|can you|could you|i want to|i spent|i have|as completed|as done|completed|done)\b'),
      '',
    );

    // Remove extracted date/time/amount segments if present
    if (extractedDateWord != null && extractedDateWord.isNotEmpty) {
      cleaned = cleaned.replaceAll(extractedDateWord, '');
    }
    if (extractedTimeWord != null && extractedTimeWord.isNotEmpty) {
      cleaned = cleaned.replaceAll(extractedTimeWord, '');
    }
    if (extractedAmountWord != null && extractedAmountWord.isNotEmpty) {
      cleaned = cleaned.replaceAll(extractedAmountWord, '');
    }

    // Clean filler prepositions at start/end
    cleaned = cleaned.replaceAll(RegExp(r'\b(for|on|at|by|in|to|my|the|an|a|of|rupees|rs)\b'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) {
      return 'Untitled Item';
    }

    // Capitalize first letter
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}

class DateParseResult {
  final DateTime dateTime;
  final String label;
  final String? matchedWord;

  DateParseResult({
    required this.dateTime,
    required this.label,
    this.matchedWord,
  });
}

class TimeParseResult {
  final TimeOfDay timeOfDay;
  final String formattedString;
  final String? matchedWord;

  TimeParseResult({
    required this.timeOfDay,
    required this.formattedString,
    this.matchedWord,
  });
}

class AmountParseResult {
  final double? amount;
  final String? matchedWord;

  AmountParseResult({
    required this.amount,
    this.matchedWord,
  });
}
