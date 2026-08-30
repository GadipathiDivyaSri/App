import 'command_models.dart';

class IntentDetector {
  /// Normalize incoming text
  static String normalize(String text) {
    var s = text.toLowerCase().trim();

    // Replace punctuation with spaces
    s = s.replaceAll(RegExp(r'[!?,;]'), ' ');

    // Remove filler words
    s = s.replaceAll(RegExp(r'\b(hey|hello|hi|please|can you|could you|would you|kindly|assistant|wrindha)\b'), ' ');

    // Condense whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Split multi-action commands joined by 'and', ';', or commas
  static List<String> splitMultiCommands(String rawText) {
    final lower = rawText.trim();
    // Split on ' and ', ' & ', ';'
    final parts = lower.split(RegExp(r'\s+(?:and|&)\s+|;'));
    if (parts.length > 1) {
      return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    }
    return [rawText.trim()];
  }

  /// Detect intent from normalized text
  static SmartIntent detectIntent(String normalized) {
    if (normalized.isEmpty) return SmartIntent.greeting;

    // Greetings & Help
    if (RegExp(r'^(hi|hello|hey|greetings|good morning|good evening|who are you|what can you do)').hasMatch(normalized)) {
      return SmartIntent.greeting;
    }
    if (RegExp(r'\b(help|commands|guide|instructions|what do you support)\b').hasMatch(normalized)) {
      return SmartIntent.help;
    }

    // Confirmation / Cancellation
    if (RegExp(r'^(yes|confirm|proceed|ok|sure|apply plan|do it|delete it)$').hasMatch(normalized)) {
      return SmartIntent.confirmAction;
    }
    if (RegExp(r'^(no|cancel|stop|nevermind|abort|discard)$').hasMatch(normalized)) {
      return SmartIntent.cancelAction;
    }

    // -------------------------------------------------------------------------
    // 12. Smart Commands (Highest Priority Matches)
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(what should i do now|what to do now|what should i focus on|what next|what is next|what is most important|recommend action|suggest focus)\b').hasMatch(normalized)) {
      return SmartIntent.smartWhatToDoNow;
    }

    if (RegExp(r'\b(plan my day|organize my day|create my schedule|schedule my day|make my plan|generate schedule|daily plan)\b').hasMatch(normalized)) {
      return SmartIntent.smartPlanMyDay;
    }

    if (RegExp(r'\b(when am i free|find free time|free slots?|available time|free time tomorrow|when can i work on|find study slot)\b').hasMatch(normalized)) {
      return SmartIntent.smartFindFreeTime;
    }

    if (RegExp(r'\b(am i overloaded|overload check|check workload|schedule overload|too much work)\b').hasMatch(normalized)) {
      return SmartIntent.smartOverloadCheck;
    }

    if (RegExp(r'\b(deadline risk|risk of missing|check deadlines|approaching deadlines|overdue risk)\b').hasMatch(normalized)) {
      return SmartIntent.smartDeadlineRisk;
    }

    if (RegExp(r'\b(missed tasks?|recover missed tasks?|reschedule overdue)\b').hasMatch(normalized)) {
      return SmartIntent.smartMissedTaskRecovery;
    }

    // -------------------------------------------------------------------------
    // 1. Task Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(add|create|new|schedule|insert|set up)\s+(?:a\s+)?task\b').hasMatch(normalized) ||
        (RegExp(r'\b(add|create)\b').hasMatch(normalized) && RegExp(r'\b(assignment|homework|revision|study|task|project)\b').hasMatch(normalized))) {
      return SmartIntent.createTask;
    }

    if (RegExp(r'\b(mark|complete|finish|done with)\s+(?:the\s+)?task\b').hasMatch(normalized) ||
        RegExp(r'\b(mark\s+.+\s+(?:as\s+)?completed?|finished\s+.+\s+task)\b').hasMatch(normalized)) {
      return SmartIntent.completeTask;
    }

    if (RegExp(r'\b(delete|remove|erase)\s+(?:the\s+)?task\b').hasMatch(normalized)) {
      return SmartIntent.deleteTask;
    }

    if (RegExp(r'\b(reschedule|move|postpone|shift)\s+(?:the\s+)?task\b').hasMatch(normalized) ||
        RegExp(r'\bmove\s+.+\s+to\b').hasMatch(normalized)) {
      return SmartIntent.rescheduleTask;
    }

    if (RegExp(r'\b(pending|incomplete|remaining)\s+tasks?\b').hasMatch(normalized) ||
        RegExp(r'\bwhat tasks? (are|is) pending\b').hasMatch(normalized)) {
      return SmartIntent.getPendingTasks;
    }

    if (RegExp(r'\b(overdue|late)\s+tasks?\b').hasMatch(normalized)) {
      return SmartIntent.getOverdueTasks;
    }

    if (RegExp(r'\b(show|list|get|view|my)\s+tasks?\b').hasMatch(normalized) ||
        normalized == 'tasks') {
      return SmartIntent.getTasks;
    }

    // -------------------------------------------------------------------------
    // 2. Habit Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(create|add|start|new)\s+(?:a\s+)?habit\b').hasMatch(normalized)) {
      return SmartIntent.createHabit;
    }

    if (RegExp(r'\b(mark\s+.+\s+habit\s+completed?|complete\s+(?:my\s+)?habit|finished\s+.+\s+habit|done with\s+.+\s+habit)\b').hasMatch(normalized) ||
        RegExp(r'\b(finished meditation|completed reading|done with workout|finished workout|did meditation|reading is done|finished gym)\b').hasMatch(normalized)) {
      return SmartIntent.completeHabit;
    }

    if (RegExp(r'\b(unmark|uncomplete|undo)\s+habit\b').hasMatch(normalized)) {
      return SmartIntent.uncompleteHabit;
    }

    if (RegExp(r'\b(delete|remove)\s+habit\b').hasMatch(normalized)) {
      return SmartIntent.deleteHabit;
    }

    if (RegExp(r'\b(habit\s+streak|my streak|streaks?)\b').hasMatch(normalized)) {
      return SmartIntent.getHabitStreak;
    }

    if (RegExp(r'\b(pending|remaining)\s+habits?\b').hasMatch(normalized) ||
        RegExp(r'\bwhat habits? (are|is) remaining\b').hasMatch(normalized)) {
      return SmartIntent.getPendingHabits;
    }

    if (RegExp(r'\b(show|list|get|view|my)\s+habits?\b').hasMatch(normalized) ||
        normalized == 'habits') {
      return SmartIntent.getHabits;
    }

    // -------------------------------------------------------------------------
    // 4. Expense Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(spent|spent on|paid|cost|add expense|log expense|bought|purchased|for transport|for food)\b').hasMatch(normalized) ||
        RegExp(r'(?:₹|rs\.?|rupees|\d+)\s+(?:on|for)\s+[a-z]+').hasMatch(normalized)) {
      return SmartIntent.addExpense;
    }

    if (RegExp(r'\b(how much did i spend|total expenses?|expense summary|spending summary|monthly spending|my budget|how much spent)\b').hasMatch(normalized)) {
      return SmartIntent.expenseSummary;
    }

    if (RegExp(r'\b(show|list|get|view)\s+expenses?\b').hasMatch(normalized)) {
      return SmartIntent.getExpenses;
    }

    if (RegExp(r'\b(delete|remove)\s+expense\b').hasMatch(normalized)) {
      return SmartIntent.deleteExpense;
    }

    // -------------------------------------------------------------------------
    // 3. Goal Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(create|add|set)\s+(?:a\s+)?goal\b').hasMatch(normalized)) {
      return SmartIntent.createGoal;
    }

    if (RegExp(r'\b(complete|achieved|finished)\s+(?:my\s+)?goal\b').hasMatch(normalized)) {
      return SmartIntent.completeGoal;
    }

    if (RegExp(r'\b(goal progress|goals progress|how are my goals)\b').hasMatch(normalized)) {
      return SmartIntent.getGoalProgress;
    }

    if (RegExp(r'\b(what should i do for my goal|next goal step|next goal action)\b').hasMatch(normalized)) {
      return SmartIntent.nextGoalAction;
    }

    if (RegExp(r'\b(show|list|get|view)\s+goals?\b').hasMatch(normalized) || normalized == 'goals') {
      return SmartIntent.getGoals;
    }

    // -------------------------------------------------------------------------
    // 5. Calendar Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(add|schedule|create)\s+(?:a\s+)?(?:meeting|event|appointment|class)\b').hasMatch(normalized)) {
      return SmartIntent.createCalendarEvent;
    }

    if (RegExp(r'\b(whats? on my calendar|calendar today|calendar events|show calendar|schedule today)\b').hasMatch(normalized)) {
      return SmartIntent.getCalendarEvents;
    }

    if (RegExp(r'\b(delete|cancel|remove)\s+(?:the\s+)?(?:meeting|event|appointment)\b').hasMatch(normalized)) {
      return SmartIntent.deleteCalendarEvent;
    }

    // -------------------------------------------------------------------------
    // 6. Subject Planner Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(add|create)\s+[a-z\s]+\s+as (?:a\s+)?subject\b').hasMatch(normalized) ||
        RegExp(r'\badd subject\b').hasMatch(normalized)) {
      return SmartIntent.createSubject;
    }

    if (RegExp(r'\b(add|create)\s+.+\s+to\s+[a-z\s]+\b').hasMatch(normalized) && RegExp(r'\b(topic|chapter|unit)\b').hasMatch(normalized)) {
      return SmartIntent.createTopic;
    }

    if (RegExp(r'\b(i finished|completed|done with)\s+.+\s+(?:in|chapter|topic|unit)\b').hasMatch(normalized)) {
      return SmartIntent.completeTopic;
    }

    if (RegExp(r'\b(subject progress|how much of\s+[a-z]+\s+is completed|study summary)\b').hasMatch(normalized)) {
      return SmartIntent.getSubjectProgress;
    }

    if (RegExp(r'\b(what should i study now|recommend study|suggest subject)\b').hasMatch(normalized)) {
      return SmartIntent.recommendStudy;
    }

    if (RegExp(r'\b(show|list|get)\s+subjects?\b').hasMatch(normalized)) {
      return SmartIntent.getSubjects;
    }

    // -------------------------------------------------------------------------
    // 7. Timetable Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(timetable today|whats my timetable|show timetable|view timetable)\b').hasMatch(normalized)) {
      return SmartIntent.getTimetable;
    }

    if (RegExp(r'\b(add|schedule)\s+.+\s+class\b').hasMatch(normalized)) {
      return SmartIntent.createTimetableEntry;
    }

    // -------------------------------------------------------------------------
    // 8. Journal Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(write in my journal|add journal|log diary|write note|journal entry|dear diary)\b').hasMatch(normalized) ||
        RegExp(r'\btoday was (?:very\s+)?(good|productive|great|bad|tiring|awesome)\b').hasMatch(normalized)) {
      return SmartIntent.createJournalEntry;
    }

    if (RegExp(r'\b(show|view|get|list)\s+journal\b').hasMatch(normalized)) {
      return SmartIntent.getJournalEntries;
    }

    if (RegExp(r'\b(find|search)\s+(?:my\s+)?(?:journal|entry|entries|notes?)\b').hasMatch(normalized)) {
      return SmartIntent.searchJournal;
    }

    // -------------------------------------------------------------------------
    // 9. Priority & Eisenhower Matrix Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(show my priority matrix|view priority matrix|priority matrix)\b').hasMatch(normalized)) {
      return SmartIntent.getPriorityMatrix;
    }

    if (RegExp(r'\b(what is my highest priority|highest priority|what should i do first|top priority)\b').hasMatch(normalized)) {
      return SmartIntent.getHighestPriority;
    }

    if (RegExp(r'\b(prioritize my tasks|auto prioritize|organize priority)\b').hasMatch(normalized)) {
      return SmartIntent.prioritizeTasks;
    }

    if (RegExp(r'\b(eisenhower matrix|show eisenhower|do now tasks?|urgent important)\b').hasMatch(normalized)) {
      return SmartIntent.getEisenhowerMatrix;
    }

    // -------------------------------------------------------------------------
    // 10. Career Roadmap Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(career roadmap|show roadmap|career steps?|next career step|career path)\b').hasMatch(normalized)) {
      return SmartIntent.getCareerRoadmap;
    }

    if (RegExp(r'\b(add|create)\s+career\s+(?:step|milestone|node)\b').hasMatch(normalized)) {
      return SmartIntent.createCareerMilestone;
    }

    if (RegExp(r'\b(complete|finished|mark)\s+.+\s+certification\b').hasMatch(normalized)) {
      return SmartIntent.completeCareerMilestone;
    }

    // -------------------------------------------------------------------------
    // 11. Analytics Commands
    // -------------------------------------------------------------------------
    if (RegExp(r'\b(how productive was i|productivity trend|productivity score|show my progress|my analytics|weekly progress)\b').hasMatch(normalized)) {
      return SmartIntent.getDailyAnalytics;
    }

    return SmartIntent.unknown;
  }
}
