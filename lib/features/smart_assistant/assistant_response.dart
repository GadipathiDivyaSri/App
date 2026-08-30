import 'package:flutter/material.dart';
import '../../providers/app_provider.dart';
import 'command_models.dart';
import 'rules/task_rules.dart';
import 'rules/habit_rules.dart';
import 'rules/goal_rules.dart';
import 'rules/expense_rules.dart';
import 'rules/calendar_rules.dart';
import 'rules/subject_rules.dart';
import 'rules/timetable_rules.dart';
import 'rules/journal_rules.dart';
import 'rules/priority_eisenhower_rules.dart';
import 'rules/career_rules.dart';
import 'rules/analytics_rules.dart';
import 'rules/smart_rules.dart';

class AssistantResponseBuilder {
  /// Build response for a detected intent and entities
  static AssistantMessage build({
    required SmartIntent intent,
    required ExtractedEntities entities,
    required AppProvider provider,
    String? rawInput,
  }) {
    switch (intent) {
      // 1. Task Commands
      case SmartIntent.createTask:
      case SmartIntent.updateTask:
      case SmartIntent.completeTask:
      case SmartIntent.deleteTask:
      case SmartIntent.rescheduleTask:
      case SmartIntent.getTasks:
      case SmartIntent.getPendingTasks:
      case SmartIntent.getOverdueTasks:
        return TaskRules.handle(intent: intent, entities: entities, provider: provider);

      // 2. Habit Commands
      case SmartIntent.createHabit:
      case SmartIntent.completeHabit:
      case SmartIntent.uncompleteHabit:
      case SmartIntent.deleteHabit:
      case SmartIntent.getHabits:
      case SmartIntent.getPendingHabits:
      case SmartIntent.getHabitStreak:
        return HabitRules.handle(intent: intent, entities: entities, provider: provider);

      // 3. Goal Commands
      case SmartIntent.createGoal:
      case SmartIntent.updateGoal:
      case SmartIntent.completeGoal:
      case SmartIntent.getGoals:
      case SmartIntent.getGoalProgress:
      case SmartIntent.nextGoalAction:
        return GoalRules.handle(intent: intent, entities: entities, provider: provider);

      // 4. Expense Commands
      case SmartIntent.addExpense:
      case SmartIntent.deleteExpense:
      case SmartIntent.getExpenses:
      case SmartIntent.expenseSummary:
        return ExpenseRules.handle(intent: intent, entities: entities, provider: provider);

      // 5. Calendar Commands
      case SmartIntent.createCalendarEvent:
      case SmartIntent.updateCalendarEvent:
      case SmartIntent.deleteCalendarEvent:
      case SmartIntent.getCalendarEvents:
        return CalendarRules.handle(intent: intent, entities: entities, provider: provider);

      // 6. Subject Planner Commands
      case SmartIntent.createSubject:
      case SmartIntent.createTopic:
      case SmartIntent.completeTopic:
      case SmartIntent.getSubjects:
      case SmartIntent.getSubjectProgress:
      case SmartIntent.recommendStudy:
        return SubjectRules.handle(intent: intent, entities: entities, provider: provider);

      // 7. Timetable Commands
      case SmartIntent.createTimetableEntry:
      case SmartIntent.updateTimetableEntry:
      case SmartIntent.deleteTimetableEntry:
      case SmartIntent.getTimetable:
      case SmartIntent.findFreeTime:
        return TimetableRules.handle(intent: intent, entities: entities, provider: provider);

      // 8. Journal Commands
      case SmartIntent.createJournalEntry:
      case SmartIntent.getJournalEntries:
      case SmartIntent.searchJournal:
        return JournalRules.handle(intent: intent, entities: entities, provider: provider, rawInput: rawInput);

      // 9. Priority & Eisenhower Matrix Commands
      case SmartIntent.getPriorityMatrix:
      case SmartIntent.addPriorityItem:
      case SmartIntent.movePriorityItem:
      case SmartIntent.getHighestPriority:
      case SmartIntent.prioritizeTasks:
      case SmartIntent.getEisenhowerMatrix:
      case SmartIntent.addEisenhowerItem:
      case SmartIntent.getDoNowTasks:
      case SmartIntent.recommendEisenhowerAction:
        return PriorityEisenhowerRules.handle(intent: intent, entities: entities, provider: provider);

      // 10. Career Roadmap Commands
      case SmartIntent.getCareerRoadmap:
      case SmartIntent.createCareerMilestone:
      case SmartIntent.completeCareerMilestone:
      case SmartIntent.nextCareerAction:
        return CareerRules.handle(intent: intent, entities: entities, provider: provider);

      // 11. Analytics Commands
      case SmartIntent.getDailyAnalytics:
      case SmartIntent.getWeeklyAnalytics:
      case SmartIntent.getMonthlyAnalytics:
      case SmartIntent.getProductivityTrend:
        return AnalyticsRules.handle(intent: intent, entities: entities, provider: provider);

      // 12. Smart Commands
      case SmartIntent.smartWhatToDoNow:
      case SmartIntent.smartPlanMyDay:
      case SmartIntent.smartFindFreeTime:
      case SmartIntent.smartOverloadCheck:
      case SmartIntent.smartDeadlineRisk:
      case SmartIntent.smartMissedTaskRecovery:
        return SmartRules.handle(intent: intent, entities: entities, provider: provider);

      case SmartIntent.greeting:
        return AssistantMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Hi! I\'m your **Wrindha Smart Assistant** 👋\nI can help you manage your tasks, habits, goals, schedule, expenses, and study planner. Just tell me what you want to do!',
          isUser: false,
          timestamp: DateTime.now(),
          suggestionChips: [
            'What should I do now?',
            'Plan my day',
            'Show my tasks',
            'Mark habit completed',
            'Show my progress',
          ],
        );

      case SmartIntent.help:
        return AssistantMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          text: '💡 **Commands I Support**:\n'
              '• **Tasks**: *"Add physics homework tomorrow"*, *"Show pending tasks"*, *"Mark task done"*\n'
              '• **Habits**: *"Mark reading done"*, *"Create gym habit"*, *"Show habits"*\n'
              '• **Expenses**: *"I spent ₹250 on food"*, *"How much did I spend this month?"*\n'
              '• **Studies**: *"Add Math subject"*, *"What should I study now?"*\n'
              '• **Smart**: *"What should I do now?"*, *"Plan my day"*, *"When am I free?"*',
          isUser: false,
          timestamp: DateTime.now(),
          suggestionChips: ['What should I do now?', 'Plan my day', 'Show my tasks'],
        );

      case SmartIntent.confirmAction:
        return AssistantMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          text: '✅ Action confirmed and applied.',
          isUser: false,
          timestamp: DateTime.now(),
          suggestionChips: ['What should I do now?', 'Show my tasks'],
        );

      case SmartIntent.cancelAction:
        return AssistantMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Action cancelled. What else can I help you with?',
          isUser: false,
          timestamp: DateTime.now(),
          suggestionChips: ['Plan my day', 'Show my tasks'],
        );

      case SmartIntent.unknown:
      default:
        return AssistantMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          text: 'I didn\'t fully understand that. Try asking me to manage your tasks, habits, goals, expenses, schedule, subjects, or productivity!',
          isUser: false,
          timestamp: DateTime.now(),
          suggestionChips: [
            'What should I do now?',
            'Plan my day',
            'Show my tasks',
            'Show my habits',
          ],
        );
    }
  }

  /// Handle button payload clicks (e.g. 'CONFIRM_DELETE_TASK_123')
  static AssistantMessage handlePayload(String payload, AppProvider provider) {
    if (payload.startsWith('CONFIRM_DELETE_TASK_')) {
      final taskId = payload.replaceFirst('CONFIRM_DELETE_TASK_', '');
      provider.deleteTask(taskId);
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🗑️ Task deleted successfully.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my tasks', 'Plan my day'],
      );
    }

    if (payload.startsWith('CONFIRM_DELETE_HABIT_')) {
      final habitId = payload.replaceFirst('CONFIRM_DELETE_HABIT_', '');
      provider.deleteHabit(habitId);
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🗑️ Habit deleted successfully.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my habits'],
      );
    }

    if (payload.startsWith('CONFIRM_DELETE_EXPENSE_')) {
      final expId = payload.replaceFirst('CONFIRM_DELETE_EXPENSE_', '');
      provider.deleteExpense(expId);
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🗑️ Expense entry deleted.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my expenses'],
      );
    }

    if (payload.startsWith('MARK_DONE_')) {
      final taskId = payload.replaceFirst('MARK_DONE_', '');
      provider.toggleTaskCompletion(taskId);
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🎉 Marked task as completed!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['What should I do now?', 'Show my tasks'],
      );
    }

    if (payload.startsWith('MARK_HABIT_DONE_')) {
      final habitId = payload.replaceFirst('MARK_HABIT_DONE_', '');
      provider.toggleHabit(habitId);
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🔥 Habit marked as completed today!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my habits', 'What should I do now?'],
      );
    }

    if (payload == 'APPLY_DAY_PLAN') {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '✅ Applied optimized daily plan to your schedule!',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['What should I do now?', 'Show my tasks'],
      );
    }

    if (payload == 'RESCHEDULE_OVERDUE_TOMORROW') {
      final overdue = provider.tasks.where((t) => !t.isCompleted && t.dueDateLabel != 'Today').toList();
      for (final t in overdue) {
        t.dueDateLabel = 'Tomorrow';
        t.dueDate = DateTime.now().add(const Duration(days: 1));
      }
      provider.notifyListeners();
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: '🗓️ Successfully rescheduled all overdue tasks to Tomorrow.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['Show my tasks', 'Plan my day'],
      );
    }

    if (payload == 'CANCEL_ACTION') {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Action cancelled.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestionChips: ['What should I do now?', 'Show my tasks'],
      );
    }

    return AssistantMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: 'Action processed.',
      isUser: false,
      timestamp: DateTime.now(),
      suggestionChips: ['What should I do now?'],
    );
  }
}
