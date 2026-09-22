import 'package:flutter/material.dart';

/// Supported Subscription Plan Tiers in WrindhaOS
enum SubscriptionPlanType {
  free,
  pro,
}

extension SubscriptionPlanTypeExtension on SubscriptionPlanType {
  String get nameCode {
    switch (this) {
      case SubscriptionPlanType.free:
        return 'FREE';
      case SubscriptionPlanType.pro:
        return 'PRO';
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionPlanType.free:
        return 'Free Plan';
      case SubscriptionPlanType.pro:
        return 'WrindhaOS Pro';
    }
  }

  bool get isPro => this == SubscriptionPlanType.pro;
}

/// Centralized Enum for all Features across WrindhaOS
enum AppFeature {
  todo,
  calendar,
  habits,
  subjects,
  goals,
  priorityMatrix,
  eisenhowerMatrix,
  expenseTracker,
  notes,
  milestones,
  careerRoadmap,
  focusTimer,
  analytics,
}

extension AppFeatureExtension on AppFeature {
  String get id {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case AppFeature.todo:
        return 'Unlimited To-Do List';
      case AppFeature.calendar:
        return 'Productivity Calendar';
      case AppFeature.habits:
        return 'Habit Tracker';
      case AppFeature.subjects:
        return 'Subject & Syllabus Planner';
      case AppFeature.goals:
        return 'Goal Pyramid Management';
      case AppFeature.priorityMatrix:
        return 'Priority Matrix (Eisenhower)';
      case AppFeature.eisenhowerMatrix:
        return 'Organize Matrix';
      case AppFeature.expenseTracker:
        return 'Expense & Student Budget Tracker';
      case AppFeature.notes:
        return 'Notes & Daily Journaling';
      case AppFeature.milestones:
        return 'Achieved Milestones';
      case AppFeature.careerRoadmap:
        return 'Career Roadmap Builder';
      case AppFeature.focusTimer:
        return 'Deep Focus Timer';
      case AppFeature.analytics:
        return 'Analytics & Insights';
    }
  }

  String get description {
    switch (this) {
      case AppFeature.todo:
        return 'Organize and check off your daily action items.';
      case AppFeature.calendar:
        return 'View and plan deadlines and upcoming schedules.';
      case AppFeature.habits:
        return 'Build long-term positive routines and streaks.';
      case AppFeature.subjects:
        return 'Track study units and syllabus progress.';
      case AppFeature.goals:
        return 'Break down your vision into actionable milestones.';
      case AppFeature.priorityMatrix:
        return 'Categorize tasks by urgency and importance.';
      case AppFeature.eisenhowerMatrix:
        return 'Strategic 4-quadrant action allocation.';
      case AppFeature.expenseTracker:
        return 'Manage income, daily expenses, and remaining budgets.';
      case AppFeature.notes:
        return 'Capture quick thoughts, reflections, and insights.';
      case AppFeature.milestones:
        return 'Celebrate and archive your key achievements.';
      case AppFeature.careerRoadmap:
        return 'Plan your long-term skill acquisition and career ladder.';
      case AppFeature.focusTimer:
        return 'Distraction-free Pomodoro and custom interval timer.';
      case AppFeature.analytics:
        return 'Review your weekly productivity and study trends.';
    }
  }

  String get unlockTitle {
    switch (this) {
      case AppFeature.habits:
        return 'Unlock Unlimited Habits';
      case AppFeature.subjects:
        return 'Unlock Unlimited Subjects';
      case AppFeature.goals:
        return 'Unlock Goal Management';
      case AppFeature.priorityMatrix:
        return 'Unlock Priority Matrix';
      case AppFeature.eisenhowerMatrix:
        return 'Unlock Eisenhower Matrix';
      case AppFeature.expenseTracker:
        return 'Unlock Expense Tracker';
      case AppFeature.notes:
        return 'Unlock Journal & Notes';
      case AppFeature.milestones:
        return 'Unlock Achieved Milestones';
      case AppFeature.careerRoadmap:
        return 'Unlock Your Career Roadmap';
      case AppFeature.focusTimer:
        return 'Unlock Deep Focus';
      case AppFeature.analytics:
        return 'Unlock Analytics & Insights';
      case AppFeature.todo:
        return 'Unlock Unlimited To-Do List';
      case AppFeature.calendar:
        return 'Unlock Productivity Calendar';
    }
  }

  String get benefitDescription {
    switch (this) {
      case AppFeature.habits:
        return "You've reached the Free plan limit of 2 habits. Upgrade to WrindhaOS Pro to create and track unlimited habits.";
      case AppFeature.subjects:
        return "You've reached the Free plan limit of 2 subjects. Upgrade to WrindhaOS Pro to manage unlimited subjects and organize your complete learning journey.";
      case AppFeature.goals:
        return 'Set ambitious goals, break them down into actionable milestones, and track your achievements with structured hierarchy.';
      case AppFeature.priorityMatrix:
        return 'Triage urgent and critical tasks with automated quadrant prioritization.';
      case AppFeature.eisenhowerMatrix:
        return 'Organize tasks by urgency and importance to eliminate distractions and execute what matters.';
      case AppFeature.expenseTracker:
        return 'Track your spending, manage personal budgets, and stay in control of your financial health.';
      case AppFeature.notes:
        return 'Capture daily reflections, ideas, and knowledge entries with formatted productivity notes.';
      case AppFeature.milestones:
        return 'Celebrate and review your personal, academic, and career milestones over time.';
      case AppFeature.careerRoadmap:
        return 'Map out your professional goals, track career pathways, and visualize skill node milestones.';
      case AppFeature.focusTimer:
        return 'Boost your attention span with customizable Pomodoro sessions, stopwatch logs, and focus heatmaps.';
      case AppFeature.analytics:
        return 'Understand your productivity, track your progress, and discover patterns that help you improve.';
      case AppFeature.todo:
        return 'Capture and organize all your daily action items without any limits.';
      case AppFeature.calendar:
        return 'Keep your schedule synchronized and never miss important deadlines.';
    }
  }

  IconData get icon {
    switch (this) {
      case AppFeature.todo:
        return Icons.checklist_rounded;
      case AppFeature.calendar:
        return Icons.calendar_month_rounded;
      case AppFeature.habits:
        return Icons.track_changes_rounded;
      case AppFeature.subjects:
        return Icons.menu_book_rounded;
      case AppFeature.goals:
        return Icons.military_tech_rounded;
      case AppFeature.priorityMatrix:
        return Icons.grid_view_rounded;
      case AppFeature.eisenhowerMatrix:
        return Icons.dashboard_customize_rounded;
      case AppFeature.expenseTracker:
        return Icons.account_balance_wallet_rounded;
      case AppFeature.notes:
        return Icons.edit_note_rounded;
      case AppFeature.milestones:
        return Icons.emoji_events_rounded;
      case AppFeature.careerRoadmap:
        return Icons.alt_route_rounded;
      case AppFeature.focusTimer:
        return Icons.timer_outlined;
      case AppFeature.analytics:
        return Icons.insights_rounded;
    }
  }
}

/// Limits and feature sets configured per subscription tier
class PlanConfiguration {
  final SubscriptionPlanType planType;
  final String title;
  final String description;
  final int maxHabits; // -1 represents unlimited
  final int maxSubjects; // -1 represents unlimited
  final Set<AppFeature> accessibleFeatures;

  const PlanConfiguration({
    required this.planType,
    required this.title,
    required this.description,
    required this.maxHabits,
    required this.maxSubjects,
    required this.accessibleFeatures,
  });

  bool get isHabitsUnlimited => maxHabits == -1;
  bool get isSubjectsUnlimited => maxSubjects == -1;
}

/// Centralized Plan Registry
class SubscriptionRegistry {
  static const int unlimited = -1;

  // FREE PLAN SPECIFICATION
  static const PlanConfiguration freePlan = PlanConfiguration(
    planType: SubscriptionPlanType.free,
    title: 'Free Plan',
    description: 'Essential organization tools to get started.',
    maxHabits: 2,
    maxSubjects: 2,
    accessibleFeatures: {
      AppFeature.todo,
      AppFeature.calendar,
      AppFeature.habits,
      AppFeature.subjects,
    },
  );

  // PRO PLAN SPECIFICATION
  static const PlanConfiguration proPlan = PlanConfiguration(
    planType: SubscriptionPlanType.pro,
    title: 'WrindhaOS Pro',
    description: 'Full, unlocked access to all productivity & study modules.',
    maxHabits: unlimited,
    maxSubjects: unlimited,
    accessibleFeatures: {
      AppFeature.todo,
      AppFeature.calendar,
      AppFeature.habits,
      AppFeature.subjects,
      AppFeature.goals,
      AppFeature.priorityMatrix,
      AppFeature.eisenhowerMatrix,
      AppFeature.expenseTracker,
      AppFeature.notes,
      AppFeature.milestones,
      AppFeature.careerRoadmap,
      AppFeature.focusTimer,
      AppFeature.analytics,
    },
  );

  /// Map of all active plan configurations
  static const Map<SubscriptionPlanType, PlanConfiguration> plans = {
    SubscriptionPlanType.free: freePlan,
    SubscriptionPlanType.pro: proPlan,
  };

  /// Retrieve configuration for a given plan
  static PlanConfiguration getConfig(SubscriptionPlanType type) {
    return plans[type] ?? freePlan;
  }

  /// Parse plan string (e.g. 'FREE', 'PRO') into SubscriptionPlanType
  static SubscriptionPlanType parsePlanString(String? planStr) {
    if (planStr == null) return SubscriptionPlanType.free;
    final normalized = planStr.trim().toUpperCase();
    if (normalized == 'PRO' || normalized == 'PRO_MONTHLY' || normalized == 'PREMIUM') {
      return SubscriptionPlanType.pro;
    }
    return SubscriptionPlanType.free;
  }
}
