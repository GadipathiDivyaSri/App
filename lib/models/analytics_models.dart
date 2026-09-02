import 'package:flutter/material.dart';

enum AnalyticsDateRangeType {
  thisWeek,
  thisMonth,
  lastMonth,
  custom,
}

enum InsightSentiment {
  positive,
  neutral,
  warning,
  info,
}

class DateRangePeriod {
  final AnalyticsDateRangeType type;
  final DateTime start;
  final DateTime end;
  final DateTime previousStart;
  final DateTime previousEnd;
  final String label;

  DateRangePeriod({
    required this.type,
    required this.start,
    required this.end,
    required this.previousStart,
    required this.previousEnd,
    required this.label,
  });

  factory DateRangePeriod.fromType(AnalyticsDateRangeType type, {DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    final todayClean = DateTime(now.year, now.month, now.day);

    switch (type) {
      case AnalyticsDateRangeType.thisWeek:
        final weekday = now.weekday; // 1 = Mon, 7 = Sun
        final monday = todayClean.subtract(Duration(days: weekday - 1));
        final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        final prevMonday = monday.subtract(const Duration(days: 7));
        final prevSunday = monday.subtract(const Duration(seconds: 1));
        return DateRangePeriod(
          type: type,
          start: monday,
          end: sunday,
          previousStart: prevMonday,
          previousEnd: prevSunday,
          label: 'This Week',
        );

      case AnalyticsDateRangeType.thisMonth:
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        final prevMonthFirst = DateTime(now.year, now.month - 1, 1);
        final prevMonthLast = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateRangePeriod(
          type: type,
          start: firstDay,
          end: lastDay,
          previousStart: prevMonthFirst,
          previousEnd: prevMonthLast,
          label: 'This Month',
        );

      case AnalyticsDateRangeType.lastMonth:
        final firstDay = DateTime(now.year, now.month - 1, 1);
        final lastDay = DateTime(now.year, now.month, 0, 23, 59, 59);
        final prevMonthFirst = DateTime(now.year, now.month - 2, 1);
        final prevMonthLast = DateTime(now.year, now.month - 1, 0, 23, 59, 59);
        return DateRangePeriod(
          type: type,
          start: firstDay,
          end: lastDay,
          previousStart: prevMonthFirst,
          previousEnd: prevMonthLast,
          label: 'Last Month',
        );

      case AnalyticsDateRangeType.custom:
        final s = customStart ?? todayClean.subtract(const Duration(days: 30));
        final e = customEnd ?? todayClean.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        final durationDays = e.difference(s).inDays + 1;
        final ps = s.subtract(Duration(days: durationDays));
        final pe = s.subtract(const Duration(seconds: 1));
        return DateRangePeriod(
          type: type,
          start: s,
          end: e,
          previousStart: ps,
          previousEnd: pe,
          label: 'Custom Range',
        );
    }
  }
}

class AnalyticsInsight {
  final String title;
  final String message;
  final IconData icon;
  final InsightSentiment sentiment;
  final String? metricTag;

  AnalyticsInsight({
    required this.title,
    required this.message,
    required this.icon,
    this.sentiment = InsightSentiment.neutral,
    this.metricTag,
  });
}

class TrendDataPoint {
  final String label;
  final double value;
  final double? secondaryValue;
  final bool isHighlight;

  TrendDataPoint({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.isHighlight = false,
  });
}

class CategoryDistribution {
  final String category;
  final double amount;
  final int count;
  final double percentage;
  final int colorHex;

  CategoryDistribution({
    required this.category,
    required this.amount,
    required this.count,
    required this.percentage,
    required this.colorHex,
  });
}

class OverviewAnalyticsData {
  final int overallProgressScore; // 0 - 100
  final double habitConsistency; // 0.0 - 1.0
  final int totalStudyTasksCompleted;
  final int totalStudyTasks;
  final double totalExpenses;
  final double remainingBudget;
  final double goalProgress; // 0.0 - 1.0
  final int milestonesAchieved;
  final int totalMilestones;
  final double? scoreDeltaPercent; // vs previous period
  final List<TrendDataPoint> progressTrend;
  final List<AnalyticsInsight> insights;

  OverviewAnalyticsData({
    required this.overallProgressScore,
    required this.habitConsistency,
    required this.totalStudyTasksCompleted,
    required this.totalStudyTasks,
    required this.totalExpenses,
    required this.remainingBudget,
    required this.goalProgress,
    required this.milestonesAchieved,
    required this.totalMilestones,
    this.scoreDeltaPercent,
    required this.progressTrend,
    required this.insights,
  });
}

class HabitRankingItem {
  final String id;
  final String title;
  final String category;
  final int completionsInPeriod;
  final int scheduledInPeriod;
  final double consistencyRate;
  final int streakDay;
  final int longestStreak;

  HabitRankingItem({
    required this.id,
    required this.title,
    required this.category,
    required this.completionsInPeriod,
    required this.scheduledInPeriod,
    required this.consistencyRate,
    required this.streakDay,
    required this.longestStreak,
  });
}

class HabitAnalyticsData {
  final double overallConsistency; // 0.0 - 1.0
  final int totalCompletions;
  final int bestStreak;
  final int longestStreak;
  final HabitRankingItem? mostConsistentHabit;
  final HabitRankingItem? leastConsistentHabit;
  final List<TrendDataPoint> weeklyTrend;
  final List<HabitRankingItem> habitRankings;
  final List<AnalyticsInsight> insights;

  HabitAnalyticsData({
    required this.overallConsistency,
    required this.totalCompletions,
    required this.bestStreak,
    required this.longestStreak,
    this.mostConsistentHabit,
    this.leastConsistentHabit,
    required this.weeklyTrend,
    required this.habitRankings,
    required this.insights,
  });
}

class StudySubjectDistribution {
  final String subjectName;
  final String subjectCode;
  final int colorHex;
  final int totalTasks;
  final int completedTasks;
  final double progress;

  StudySubjectDistribution({
    required this.subjectName,
    required this.subjectCode,
    required this.colorHex,
    required this.totalTasks,
    required this.completedTasks,
    required this.progress,
  });
}

class StudyAnalyticsData {
  final int totalStudyItems;
  final int completedStudyItems;
  final double completionRate;
  final int totalSubjects;
  final String? mostFocusedSubject;
  final String? leastFocusedSubject;
  final String? mostProductiveDay;
  final List<StudySubjectDistribution> subjectDistributions;
  final List<TrendDataPoint> studyTrend;
  final List<AnalyticsInsight> insights;

  StudyAnalyticsData({
    required this.totalStudyItems,
    required this.completedStudyItems,
    required this.completionRate,
    required this.totalSubjects,
    this.mostFocusedSubject,
    this.leastFocusedSubject,
    this.mostProductiveDay,
    required this.subjectDistributions,
    required this.studyTrend,
    required this.insights,
  });
}

class ExpenseAnalyticsData {
  final double totalSpent;
  final double totalIncome;
  final double monthlyBudget;
  final double remainingBudget;
  final double budgetUtilization; // 0.0 - 1.0
  final String? highestSpendingCategory;
  final String? lowestSpendingCategory;
  final double? spendDeltaPercent; // vs previous period
  final List<CategoryDistribution> categoryBreakdown;
  final List<TrendDataPoint> spendingTrend;
  final List<AnalyticsInsight> insights;

  ExpenseAnalyticsData({
    required this.totalSpent,
    required this.totalIncome,
    required this.monthlyBudget,
    required this.remainingBudget,
    required this.budgetUtilization,
    this.highestSpendingCategory,
    this.lowestSpendingCategory,
    this.spendDeltaPercent,
    required this.categoryBreakdown,
    required this.spendingTrend,
    required this.insights,
  });
}

class GoalItemAnalytics {
  final String id;
  final String title;
  final String section;
  final double progress; // 0.0 - 1.0
  final String status; // 'On Track', 'Needs Attention', 'Completed'
  final bool isCompleted;

  GoalItemAnalytics({
    required this.id,
    required this.title,
    required this.section,
    required this.progress,
    required this.status,
    required this.isCompleted,
  });
}

class GoalAnalyticsData {
  final int totalGoals;
  final int completedGoals;
  final int onTrackGoals;
  final int needsAttentionGoals;
  final double averageProgress; // 0.0 - 1.0
  final List<GoalItemAnalytics> goalItems;
  final List<AnalyticsInsight> insights;

  GoalAnalyticsData({
    required this.totalGoals,
    required this.completedGoals,
    required this.onTrackGoals,
    required this.needsAttentionGoals,
    required this.averageProgress,
    required this.goalItems,
    required this.insights,
  });
}

class MilestoneItemAnalytics {
  final String id;
  final String title;
  final String category;
  final double progress; // 0.0 - 1.0
  final bool isCompleted;
  final String? achievedDateLabel;

  MilestoneItemAnalytics({
    required this.id,
    required this.title,
    required this.category,
    required this.progress,
    required this.isCompleted,
    this.achievedDateLabel,
  });
}

class MilestoneAnalyticsData {
  final int totalMilestones;
  final int completedMilestones;
  final int inProgressMilestones;
  final int upcomingMilestones;
  final double completionRate;
  final List<MilestoneItemAnalytics> completedList;
  final List<MilestoneItemAnalytics> inProgressList;
  final List<MilestoneItemAnalytics> upcomingList;
  final List<AnalyticsInsight> insights;

  MilestoneAnalyticsData({
    required this.totalMilestones,
    required this.completedMilestones,
    required this.inProgressMilestones,
    required this.upcomingMilestones,
    required this.completionRate,
    required this.completedList,
    required this.inProgressList,
    required this.upcomingList,
    required this.insights,
  });
}
