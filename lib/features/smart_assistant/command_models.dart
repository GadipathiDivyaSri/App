import 'package:flutter/material.dart';

/// All supported Smart Assistant Intents across all 12 modules and smart features
enum SmartIntent {
  // 1. Task Commands
  createTask,
  updateTask,
  completeTask,
  deleteTask,
  rescheduleTask,
  getTasks,
  getPendingTasks,
  getOverdueTasks,

  // 2. Habit Commands
  createHabit,
  completeHabit,
  uncompleteHabit,
  deleteHabit,
  getHabits,
  getPendingHabits,
  getHabitStreak,

  // 3. Goal Commands
  createGoal,
  updateGoal,
  completeGoal,
  getGoals,
  getGoalProgress,
  nextGoalAction,

  // 4. Expense Commands
  addExpense,
  deleteExpense,
  getExpenses,
  expenseSummary,

  // 5. Calendar Commands
  createCalendarEvent,
  updateCalendarEvent,
  deleteCalendarEvent,
  getCalendarEvents,

  // 6. Subject Planner Commands
  createSubject,
  createTopic,
  completeTopic,
  getSubjects,
  getSubjectProgress,
  recommendStudy,

  // 7. Timetable Commands
  createTimetableEntry,
  updateTimetableEntry,
  deleteTimetableEntry,
  getTimetable,
  findFreeTime,

  // 8. Journal Commands
  createJournalEntry,
  getJournalEntries,
  searchJournal,

  // 9. Priority & Eisenhower Matrix Commands
  getPriorityMatrix,
  addPriorityItem,
  movePriorityItem,
  getHighestPriority,
  prioritizeTasks,
  getEisenhowerMatrix,
  addEisenhowerItem,
  getDoNowTasks,
  recommendEisenhowerAction,

  // 10. Career Roadmap Commands
  getCareerRoadmap,
  createCareerMilestone,
  completeCareerMilestone,
  nextCareerAction,

  // 11. Analytics Commands
  getDailyAnalytics,
  getWeeklyAnalytics,
  getMonthlyAnalytics,
  getProductivityTrend,

  // 12. Smart Commands
  smartWhatToDoNow,
  smartPlanMyDay,
  smartFindFreeTime,
  smartOverloadCheck,
  smartDeadlineRisk,
  smartMissedTaskRecovery,

  // General & Confirmation
  confirmAction,
  cancelAction,
  greeting,
  help,
  unknown,
}

/// Extracted entities from user natural language
class ExtractedEntities {
  final String? title;
  final String? category;
  final String? tag;
  final DateTime? date;
  final String? dateLabel;
  final TimeOfDay? time;
  final String? timeString;
  final double? amount;
  final int? priority;
  final String? frequency;
  final String? mood;
  final String? subjectName;
  final String? topicName;
  final String? location;
  final String? targetId;
  final Map<String, dynamic> extra;

  ExtractedEntities({
    this.title,
    this.category,
    this.tag,
    this.date,
    this.dateLabel,
    this.time,
    this.timeString,
    this.amount,
    this.priority,
    this.frequency,
    this.mood,
    this.subjectName,
    this.topicName,
    this.location,
    this.targetId,
    Map<String, dynamic>? extra,
  }) : extra = extra ?? {};

  ExtractedEntities copyWith({
    String? title,
    String? category,
    String? tag,
    DateTime? date,
    String? dateLabel,
    TimeOfDay? time,
    String? timeString,
    double? amount,
    int? priority,
    String? frequency,
    String? mood,
    String? subjectName,
    String? topicName,
    String? location,
    String? targetId,
    Map<String, dynamic>? extra,
  }) {
    return ExtractedEntities(
      title: title ?? this.title,
      category: category ?? this.category,
      tag: tag ?? this.tag,
      date: date ?? this.date,
      dateLabel: dateLabel ?? this.dateLabel,
      time: time ?? this.time,
      timeString: timeString ?? this.timeString,
      amount: amount ?? this.amount,
      priority: priority ?? this.priority,
      frequency: frequency ?? this.frequency,
      mood: mood ?? this.mood,
      subjectName: subjectName ?? this.subjectName,
      topicName: topicName ?? this.topicName,
      location: location ?? this.location,
      targetId: targetId ?? this.targetId,
      extra: extra ?? this.extra,
    );
  }
}

/// Action card types displayed inside assistant messages
enum ActionCardType {
  taskList,
  singleTask,
  habitList,
  goalMeter,
  expenseSummary,
  schedulePlan,
  whatToDoRecommendation,
  confirmationPrompt,
  quickOptions,
  subjectProgress,
}

/// Visual card model
class ActionCardData {
  final ActionCardType type;
  final String title;
  final String? subtitle;
  final List<ActionCardItem> items;
  final List<ActionButton> actions;
  final Map<String, dynamic>? payload;

  ActionCardData({
    required this.type,
    required this.title,
    this.subtitle,
    this.items = const [],
    this.actions = const [],
    this.payload,
  });
}

/// Single item inside an action card (e.g. task row, habit item)
class ActionCardItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool isCompleted;
  final String? trailingText;
  final VoidCallback? onTap;

  ActionCardItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.isCompleted = false,
    this.trailingText,
    this.onTap,
  });
}

/// Button inside action cards
class ActionButton {
  final String label;
  final IconData? icon;
  final bool isPrimary;
  final bool isDestructive;
  final String commandPayload;
  final VoidCallback? onPressed;

  ActionButton({
    required this.label,
    this.icon,
    this.isPrimary = true,
    this.isDestructive = false,
    required this.commandPayload,
    this.onPressed,
  });
}

/// Chat message model
class AssistantMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ActionCardData? cardData;
  final List<String> suggestionChips;
  final SmartIntent? detectedIntent;

  AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.cardData,
    this.suggestionChips = const [],
    this.detectedIntent,
  });
}

/// Pending in-memory conversation context for multi-turn conversations
class ConversationContext {
  final SmartIntent pendingIntent;
  final ExtractedEntities partialEntities;
  final String waitingForField; // 'time', 'date', 'amount', 'category', 'confirmation', 'selection'
  final DateTime createdAt;
  final List<dynamic>? ambiguousOptions;

  ConversationContext({
    required this.pendingIntent,
    required this.partialEntities,
    required this.waitingForField,
    required this.createdAt,
    this.ambiguousOptions,
  });
}
