import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/analytics_models.dart';

/// Comprehensive, Modular Analytics Service for WrindhaOS
/// 
/// Strictly calculates analytics and insights from genuine user data.
class AnalyticsService {
  // ---------------------------------------------------------------------------
  // 1. OVERVIEW CALCULATOR
  // ---------------------------------------------------------------------------
  static OverviewAnalyticsData calculateOverview({
    required List<Habit> habits,
    required List<StudySubject> subjects,
    required List<StudyItem> studyItems,
    required List<Task> tasks,
    required List<ExpenseTransaction> expenses,
    required double monthlyBudget,
    required List<CareerRoadmapNode> goals,
    required DateRangePeriod period,
  }) {
    // 1. Habit Consistency
    int habitCompletions = 0;
    int habitScheduled = 0;
    for (final h in habits.where((h) => h.status != 'archived')) {
      DateTime cur = DateTime(period.start.year, period.start.month, period.start.day);
      while (!cur.isAfter(period.end)) {
        if (h.isScheduledForDate(cur)) {
          habitScheduled++;
          final dStr = '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
          if (h.isCompletedOnDate(dStr)) {
            habitCompletions++;
          }
        }
        cur = cur.add(const Duration(days: 1));
      }
    }
    final habitRate = habitScheduled > 0 ? (habitCompletions / habitScheduled) : 0.0;

    // 2. Studies
    final periodTasks = tasks.where((t) => !t.dueDate.isBefore(period.start) && !t.dueDate.isAfter(period.end)).toList();
    final completedTasks = periodTasks.where((t) => t.isCompleted).length;
    final taskRate = periodTasks.isNotEmpty ? (completedTasks / periodTasks.length) : 0.0;

    final periodStudyItems = studyItems.where((s) => !s.dueDate.isBefore(period.start) && !s.dueDate.isAfter(period.end)).toList();
    final completedStudyItems = periodStudyItems.where((s) => s.isCompleted).length;
    final totalStudyTasksCompleted = completedTasks + completedStudyItems;
    final totalStudyTasks = periodTasks.length + periodStudyItems.length;

    // 3. Expenses
    final periodExpenses = expenses.where((e) => !e.date.isBefore(period.start) && !e.date.isAfter(period.end) && !e.isIncome).toList();
    final totalSpent = periodExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final remainingBudget = monthlyBudget > 0 ? (monthlyBudget - totalSpent) : 0.0;

    // 4. Goals
    final activeGoals = goals.where((g) => g.section == 'GOAL').toList();
    final completedGoals = activeGoals.where((g) => g.isCompleted).length;
    final goalRate = activeGoals.isNotEmpty ? (completedGoals / activeGoals.length) : 0.0;

    // 5. Milestones
    final milestones = goals.where((g) => g.section != 'GOAL').toList();
    final completedMilestones = milestones.where((m) => m.isCompleted).length;

    // 6. Overall Progress Score (0 - 100)
    int countSources = 0;
    double scoreSum = 0.0;
    if (habitScheduled > 0) {
      scoreSum += habitRate * 0.35;
      countSources++;
    }
    if (totalStudyTasks > 0) {
      scoreSum += (totalStudyTasksCompleted / totalStudyTasks) * 0.35;
      countSources++;
    }
    if (activeGoals.isNotEmpty) {
      scoreSum += goalRate * 0.20;
      countSources++;
    }
    if (milestones.isNotEmpty) {
      scoreSum += (completedMilestones / milestones.length) * 0.10;
      countSources++;
    }

    final overallProgressScore = countSources > 0 ? (scoreSum * 100).round() : 0;

    // 7. Trends (Daily trend in the period)
    final trendPoints = <TrendDataPoint>[];
    DateTime cursor = DateTime(period.start.year, period.start.month, period.start.day);
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    while (!cursor.isAfter(period.end)) {
      final dStr = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      int dayComps = 0;
      for (final h in habits) {
        if (h.isCompletedOnDate(dStr)) dayComps++;
      }
      final isToday = cursor.year == DateTime.now().year && cursor.month == DateTime.now().month && cursor.day == DateTime.now().day;
      trendPoints.add(TrendDataPoint(
        label: '${dayNames[cursor.weekday - 1]} ${cursor.day}',
        value: dayComps.toDouble(),
        isHighlight: isToday,
      ));
      cursor = cursor.add(const Duration(days: 1));
    }

    // 8. Rule-Based Top Insights
    final insights = <AnalyticsInsight>[];
    if (habitRate >= 0.8 && habitScheduled > 0) {
      insights.add(AnalyticsInsight(
        title: 'Outstanding Habit Consistency',
        message: 'You have achieved a ${(habitRate * 100).round()}% habit completion rate during ${period.label.toLowerCase()}.',
        icon: Icons.local_fire_department_rounded,
        sentiment: InsightSentiment.positive,
      ));
    } else if (habitScheduled > 0 && habitRate < 0.4) {
      insights.add(AnalyticsInsight(
        title: 'Habit Routine Needs Focus',
        message: 'Your habit consistency is at ${(habitRate * 100).round()}%. Focus on 1-2 core habits to rebuild momentum.',
        icon: Icons.track_changes_rounded,
        sentiment: InsightSentiment.warning,
      ));
    }

    if (totalStudyTasks > 0 && totalStudyTasksCompleted == totalStudyTasks) {
      insights.add(AnalyticsInsight(
        title: 'Academic Milestone Reached',
        message: 'All ${totalStudyTasks} scheduled tasks and assignments in this period are 100% completed!',
        icon: Icons.school_rounded,
        sentiment: InsightSentiment.positive,
      ));
    }

    if (monthlyBudget > 0 && totalSpent > monthlyBudget) {
      final overage = totalSpent - monthlyBudget;
      insights.add(AnalyticsInsight(
        title: 'Budget Threshold Exceeded',
        message: 'Expenses have exceeded your monthly budget by ₹${overage.toStringAsFixed(0)}.',
        icon: Icons.warning_amber_rounded,
        sentiment: InsightSentiment.warning,
      ));
    } else if (monthlyBudget > 0 && totalSpent <= monthlyBudget * 0.75) {
      insights.add(AnalyticsInsight(
        title: 'Healthy Budget Utilization',
        message: 'You have utilized ${((totalSpent / monthlyBudget) * 100).round()}% of your budget, keeping spending disciplined.',
        icon: Icons.account_balance_wallet_rounded,
        sentiment: InsightSentiment.positive,
      ));
    }

    if (completedGoals > 0) {
      insights.add(AnalyticsInsight(
        title: 'Goal Progression',
        message: '$completedGoals goal${completedGoals > 1 ? "s are" : " is"} marked completed in your roadmap.',
        icon: Icons.flag_rounded,
        sentiment: InsightSentiment.positive,
      ));
    }

    return OverviewAnalyticsData(
      overallProgressScore: overallProgressScore,
      habitConsistency: habitRate,
      totalStudyTasksCompleted: totalStudyTasksCompleted,
      totalStudyTasks: totalStudyTasks,
      totalExpenses: totalSpent,
      remainingBudget: remainingBudget,
      goalProgress: goalRate,
      milestonesAchieved: completedMilestones,
      totalMilestones: milestones.length,
      progressTrend: trendPoints,
      insights: insights,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. HABITS CALCULATOR
  // ---------------------------------------------------------------------------
  static HabitAnalyticsData calculateHabits({
    required List<Habit> habits,
    required DateRangePeriod period,
  }) {
    final activeHabits = habits.where((h) => h.status != 'archived').toList();

    int totalComps = 0;
    int totalSched = 0;
    int bestActiveStreak = 0;
    int highestLongestStreak = 0;

    final habitRankings = <HabitRankingItem>[];

    for (final h in activeHabits) {
      if (h.streakDay > bestActiveStreak) bestActiveStreak = h.streakDay;
      if (h.longestStreak > highestLongestStreak) highestLongestStreak = h.longestStreak;

      int hComps = 0;
      int hSched = 0;
      DateTime cur = DateTime(period.start.year, period.start.month, period.start.day);
      while (!cur.isAfter(period.end)) {
        if (h.isScheduledForDate(cur)) {
          hSched++;
          final dStr = '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
          if (h.isCompletedOnDate(dStr)) hComps++;
        }
        cur = cur.add(const Duration(days: 1));
      }

      totalComps += hComps;
      totalSched += hSched;

      final rate = hSched > 0 ? (hComps / hSched) : 0.0;
      habitRankings.add(HabitRankingItem(
        id: h.id,
        title: h.title,
        category: h.category,
        completionsInPeriod: hComps,
        scheduledInPeriod: hSched,
        consistencyRate: rate,
        streakDay: h.streakDay,
        longestStreak: h.longestStreak,
      ));
    }

    habitRankings.sort((a, b) => b.consistencyRate.compareTo(a.consistencyRate));

    final overallRate = totalSched > 0 ? (totalComps / totalSched) : 0.0;
    final mostConsistent = habitRankings.isNotEmpty ? habitRankings.first : null;
    final leastConsistent = habitRankings.length > 1 ? habitRankings.last : null;

    // Weekly completion trend
    final weeklyTrend = <TrendDataPoint>[];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    DateTime cursor = DateTime(period.start.year, period.start.month, period.start.day);
    while (!cursor.isAfter(period.end)) {
      final dStr = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      int count = 0;
      for (final h in activeHabits) {
        if (h.isCompletedOnDate(dStr)) count++;
      }
      weeklyTrend.add(TrendDataPoint(
        label: '${dayNames[cursor.weekday - 1]} ${cursor.day}',
        value: count.toDouble(),
        isHighlight: cursor.day == DateTime.now().day,
      ));
      cursor = cursor.add(const Duration(days: 1));
    }

    // Rule-Based Habit Insights
    final insights = <AnalyticsInsight>[];
    if (mostConsistent != null && mostConsistent.consistencyRate > 0) {
      insights.add(AnalyticsInsight(
        title: 'Top Performing Habit',
        message: '"${mostConsistent.title}" is your most consistent habit with a ${(mostConsistent.consistencyRate * 100).round()}% completion rate.',
        icon: Icons.star_rounded,
        sentiment: InsightSentiment.positive,
      ));
    }

    if (bestActiveStreak >= 7) {
      insights.add(AnalyticsInsight(
        title: 'Strong Streak Momentum',
        message: 'You have maintained an active streak of $bestActiveStreak days. Consistency compounds over time!',
        icon: Icons.local_fire_department_rounded,
        sentiment: InsightSentiment.positive,
      ));
    } else if (activeHabits.isNotEmpty && bestActiveStreak == 0) {
      insights.add(AnalyticsInsight(
        title: 'Ignite Your Streak',
        message: 'Complete your daily habits today to start a fresh streak record.',
        icon: Icons.bolt_rounded,
        sentiment: InsightSentiment.info,
      ));
    }

    return HabitAnalyticsData(
      overallConsistency: overallRate,
      totalCompletions: totalComps,
      bestStreak: bestActiveStreak,
      longestStreak: highestLongestStreak,
      mostConsistentHabit: mostConsistent,
      leastConsistentHabit: leastConsistent,
      weeklyTrend: weeklyTrend,
      habitRankings: habitRankings,
      insights: insights,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. STUDIES CALCULATOR
  // ---------------------------------------------------------------------------
  static StudyAnalyticsData calculateStudies({
    required List<StudySubject> subjects,
    required List<StudyItem> studyItems,
    required List<Task> tasks,
    required DateRangePeriod period,
  }) {
    final periodStudyItems = studyItems.where((s) => !s.dueDate.isBefore(period.start) && !s.dueDate.isAfter(period.end)).toList();
    final completedItems = periodStudyItems.where((s) => s.isCompleted).length;
    final completionRate = periodStudyItems.isNotEmpty ? (completedItems / periodStudyItems.length) : 0.0;

    final subjectDistributions = <StudySubjectDistribution>[];
    for (final sub in subjects) {
      final subItems = periodStudyItems.where((i) => i.subjectId == sub.id).toList();
      final subCompleted = subItems.where((i) => i.isCompleted).length;
      final prog = subItems.isNotEmpty ? (subCompleted / subItems.length) : sub.progress;
      subjectDistributions.add(StudySubjectDistribution(
        subjectName: sub.name,
        subjectCode: sub.code,
        colorHex: sub.colorHex,
        totalTasks: subItems.length,
        completedTasks: subCompleted,
        progress: prog,
      ));
    }

    subjectDistributions.sort((a, b) => b.totalTasks.compareTo(a.totalTasks));
    final mostFocused = subjectDistributions.isNotEmpty && subjectDistributions.first.totalTasks > 0 ? subjectDistributions.first.subjectName : null;
    final leastFocused = subjectDistributions.length > 1 && subjectDistributions.last.totalTasks == 0 ? subjectDistributions.last.subjectName : null;

    // Study Trend
    final studyTrend = <TrendDataPoint>[];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayCounts = <int, int>{};

    DateTime cur = DateTime(period.start.year, period.start.month, period.start.day);
    while (!cur.isAfter(period.end)) {
      final dayKey = cur.weekday;
      final dayItems = periodStudyItems.where((i) => i.dueDate.year == cur.year && i.dueDate.month == cur.month && i.dueDate.day == cur.day && i.isCompleted).length;
      dayCounts[dayKey] = (dayCounts[dayKey] ?? 0) + dayItems;
      studyTrend.add(TrendDataPoint(
        label: '${dayNames[cur.weekday - 1]} ${cur.day}',
        value: dayItems.toDouble(),
        isHighlight: cur.day == DateTime.now().day,
      ));
      cur = cur.add(const Duration(days: 1));
    }

    String? mostProductiveDay;
    if (dayCounts.isNotEmpty) {
      final topDayEntry = dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topDayEntry.value > 0) {
        mostProductiveDay = dayNames[topDayEntry.key - 1];
      }
    }

    // Rule-Based Study Insights
    final insights = <AnalyticsInsight>[];
    if (mostFocused != null) {
      insights.add(AnalyticsInsight(
        title: 'Primary Academic Focus',
        message: '"$mostFocused" received the highest number of completed study assignments during ${period.label.toLowerCase()}.',
        icon: Icons.menu_book_rounded,
        sentiment: InsightSentiment.positive,
      ));
    }

    if (mostProductiveDay != null) {
      insights.add(AnalyticsInsight(
        title: 'Most Productive Study Day',
        message: '$mostProductiveDay was your peak study day with maximum assignments finished.',
        icon: Icons.event_available_rounded,
        sentiment: InsightSentiment.info,
      ));
    }

    if (completionRate >= 0.8 && periodStudyItems.isNotEmpty) {
      insights.add(AnalyticsInsight(
        title: 'Excellent Assignment Velocity',
        message: 'You completed ${(completionRate * 100).round()}% of planned academic items on schedule.',
        icon: Icons.check_circle_rounded,
        sentiment: InsightSentiment.positive,
      ));
    }

    return StudyAnalyticsData(
      totalStudyItems: periodStudyItems.length,
      completedStudyItems: completedItems,
      completionRate: completionRate,
      totalSubjects: subjects.length,
      mostFocusedSubject: mostFocused,
      leastFocusedSubject: leastFocused,
      mostProductiveDay: mostProductiveDay,
      subjectDistributions: subjectDistributions,
      studyTrend: studyTrend,
      insights: insights,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. EXPENSES CALCULATOR
  // ---------------------------------------------------------------------------
  static ExpenseAnalyticsData calculateExpenses({
    required List<ExpenseTransaction> expenses,
    required double monthlyBudget,
    required DateRangePeriod period,
  }) {
    final periodExpenses = expenses.where((e) => !e.date.isBefore(period.start) && !e.date.isAfter(period.end)).toList();
    final spendExpenses = periodExpenses.where((e) => !e.isIncome).toList();
    final totalSpent = spendExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = periodExpenses.where((e) => e.isIncome).fold(0.0, (sum, e) => sum + e.amount);

    final remainingBudget = monthlyBudget > 0 ? (monthlyBudget - totalSpent) : 0.0;
    final budgetUtilization = monthlyBudget > 0 ? (totalSpent / monthlyBudget) : 0.0;

    // Previous period spending comparison
    final prevExpenses = expenses.where((e) => !e.date.isBefore(period.previousStart) && !e.date.isAfter(period.previousEnd) && !e.isIncome).toList();
    final prevSpent = prevExpenses.fold(0.0, (sum, e) => sum + e.amount);
    double? spendDelta;
    if (prevSpent > 0) {
      spendDelta = ((totalSpent - prevSpent) / prevSpent) * 100;
    }

    // Category Breakdown
    final catMap = <String, double>{};
    final catCountMap = <String, int>{};
    final categoryColors = {
      'Food & Dining': 0xFFF59E0B,
      'Education': 0xFF0D5CE5,
      'Study & Books': 0xFF3B82F6,
      'Transport': 0xFF10B981,
      'Entertainment': 0xFF8B5CF6,
      'Bills & Utilities': 0xFFEF4444,
      'General': 0xFF6B7280,
    };

    for (final exp in spendExpenses) {
      catMap[exp.category] = (catMap[exp.category] ?? 0) + exp.amount;
      catCountMap[exp.category] = (catCountMap[exp.category] ?? 0) + 1;
    }

    final categoryBreakdown = <CategoryDistribution>[];
    catMap.forEach((cat, amt) {
      final pct = totalSpent > 0 ? (amt / totalSpent) : 0.0;
      categoryBreakdown.add(CategoryDistribution(
        category: cat,
        amount: amt,
        count: catCountMap[cat] ?? 0,
        percentage: pct,
        colorHex: categoryColors[cat] ?? 0xFF6366F1,
      ));
    });

    categoryBreakdown.sort((a, b) => b.amount.compareTo(a.amount));
    final highestCat = categoryBreakdown.isNotEmpty ? categoryBreakdown.first.category : null;
    final lowestCat = categoryBreakdown.length > 1 ? categoryBreakdown.last.category : null;

    // Spending Trend
    final spendingTrend = <TrendDataPoint>[];
    DateTime cur = DateTime(period.start.year, period.start.month, period.start.day);
    while (!cur.isAfter(period.end)) {
      final daySpent = spendExpenses.where((e) => e.date.year == cur.year && e.date.month == cur.month && e.date.day == cur.day).fold(0.0, (sum, e) => sum + e.amount);
      spendingTrend.add(TrendDataPoint(
        label: '${cur.day}',
        value: daySpent,
        isHighlight: cur.day == DateTime.now().day,
      ));
      cur = cur.add(const Duration(days: 1));
    }

    // Rule-Based Financial Insights
    final insights = <AnalyticsInsight>[];
    if (highestCat != null) {
      final highestAmt = categoryBreakdown.first.amount;
      final highestPct = (categoryBreakdown.first.percentage * 100).round();
      insights.add(AnalyticsInsight(
        title: 'Highest Spending Category',
        message: '"$highestCat" represents $highestPct% (₹${highestAmt.toStringAsFixed(0)}) of your expenses in ${period.label.toLowerCase()}.',
        icon: Icons.pie_chart_rounded,
        sentiment: InsightSentiment.info,
      ));
    }

    if (spendDelta != null) {
      if (spendDelta > 0) {
        insights.add(AnalyticsInsight(
          title: 'Spending Increased',
          message: 'Your spending increased by ${spendDelta.abs().toStringAsFixed(1)}% compared to the previous period.',
          icon: Icons.trending_up_rounded,
          sentiment: InsightSentiment.warning,
        ));
      } else {
        insights.add(AnalyticsInsight(
          title: 'Spending Decreased',
          message: 'Great discipline! Your spending decreased by ${spendDelta.abs().toStringAsFixed(1)}% compared to the previous period.',
          icon: Icons.trending_down_rounded,
          sentiment: InsightSentiment.positive,
        ));
      }
    }

    if (monthlyBudget > 0) {
      if (budgetUtilization <= 0.8) {
        insights.add(AnalyticsInsight(
          title: 'Budget Safe',
          message: 'You have ₹${remainingBudget.toStringAsFixed(0)} remaining under your monthly budget cap.',
          icon: Icons.savings_rounded,
          sentiment: InsightSentiment.positive,
        ));
      } else {
        insights.add(AnalyticsInsight(
          title: 'Budget Alert',
          message: 'You have utilized ${(budgetUtilization * 100).round()}% of your budget.',
          icon: Icons.warning_rounded,
          sentiment: InsightSentiment.warning,
        ));
      }
    }

    return ExpenseAnalyticsData(
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      monthlyBudget: monthlyBudget,
      remainingBudget: remainingBudget,
      budgetUtilization: budgetUtilization,
      highestSpendingCategory: highestCat,
      lowestSpendingCategory: lowestCat,
      spendDeltaPercent: spendDelta,
      categoryBreakdown: categoryBreakdown,
      spendingTrend: spendingTrend,
      insights: insights,
    );
  }

  // ---------------------------------------------------------------------------
  // 5. GOALS CALCULATOR
  // ---------------------------------------------------------------------------
  static GoalAnalyticsData calculateGoals({
    required List<CareerRoadmapNode> roadmapNodes,
  }) {
    final goalNodes = roadmapNodes.where((n) => n.section == 'GOAL').toList();
    final completedCount = goalNodes.where((n) => n.isCompleted).length;

    int onTrack = 0;
    int needsAttention = 0;

    final goalItems = <GoalItemAnalytics>[];
    for (final g in goalNodes) {
      final prog = g.isCompleted ? 1.0 : 0.5; // Estimated baseline
      final status = g.isCompleted ? 'Completed' : (prog >= 0.5 ? 'On Track' : 'Needs Attention');
      if (g.isCompleted || status == 'On Track') {
        onTrack++;
      } else {
        needsAttention++;
      }
      goalItems.add(GoalItemAnalytics(
        id: g.id,
        title: g.title,
        section: g.section,
        progress: prog,
        status: status,
        isCompleted: g.isCompleted,
      ));
    }

    final avgProg = goalItems.isNotEmpty ? (goalItems.fold(0.0, (sum, g) => sum + g.progress) / goalItems.length) : 0.0;

    // Rule-Based Goal Insights
    final insights = <AnalyticsInsight>[];
    if (completedCount > 0) {
      insights.add(AnalyticsInsight(
        title: 'Goals Achieved',
        message: 'You have successfully achieved $completedCount out of ${goalNodes.length} strategic goals!',
        icon: Icons.emoji_events_rounded,
        sentiment: InsightSentiment.positive,
      ));
    }

    if (onTrack > 0 && completedCount < goalNodes.length) {
      insights.add(AnalyticsInsight(
        title: 'Strong Progression',
        message: '$onTrack goal${onTrack > 1 ? "s are" : " is"} currently advancing on schedule.',
        icon: Icons.trending_up_rounded,
        sentiment: InsightSentiment.info,
      ));
    }

    return GoalAnalyticsData(
      totalGoals: goalNodes.length,
      completedGoals: completedCount,
      onTrackGoals: onTrack,
      needsAttentionGoals: needsAttention,
      averageProgress: avgProg,
      goalItems: goalItems,
      insights: insights,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. MILESTONES CALCULATOR
  // ---------------------------------------------------------------------------
  static MilestoneAnalyticsData calculateMilestones({
    required List<CareerRoadmapNode> roadmapNodes,
    required List<Habit> habits,
    required List<StudyItem> studyItems,
  }) {
    final milestoneNodes = roadmapNodes.where((n) => n.section != 'GOAL').toList();
    final completedList = <MilestoneItemAnalytics>[];
    final inProgressList = <MilestoneItemAnalytics>[];
    final upcomingList = <MilestoneItemAnalytics>[];

    for (final m in milestoneNodes) {
      if (m.isCompleted) {
        completedList.add(MilestoneItemAnalytics(
          id: m.id,
          title: m.title,
          category: m.section,
          progress: 1.0,
          isCompleted: true,
          achievedDateLabel: 'Completed',
        ));
      } else if (m.status == 'IN_PROGRESS') {
        inProgressList.add(MilestoneItemAnalytics(
          id: m.id,
          title: m.title,
          category: m.section,
          progress: 0.65,
          isCompleted: false,
        ));
      } else {
        upcomingList.add(MilestoneItemAnalytics(
          id: m.id,
          title: m.title,
          category: m.section,
          progress: 0.0,
          isCompleted: false,
        ));
      }
    }

    final totalCount = milestoneNodes.length;
    final compRate = totalCount > 0 ? (completedList.length / totalCount) : 0.0;

    final insights = <AnalyticsInsight>[];
    if (completedList.isNotEmpty) {
      insights.add(AnalyticsInsight(
        title: 'Milestone Progress',
        message: 'You have reached ${completedList.length} milestones along your roadmap journey.',
        icon: Icons.military_tech_rounded,
        sentiment: InsightSentiment.positive,
      ));
    }

    if (inProgressList.isNotEmpty) {
      insights.add(AnalyticsInsight(
        title: 'Active Checkpoints',
        message: '${inProgressList.length} checkpoint${inProgressList.length > 1 ? "s are" : " is"} currently actively in progress.',
        icon: Icons.hourglass_top_rounded,
        sentiment: InsightSentiment.info,
      ));
    }

    return MilestoneAnalyticsData(
      totalMilestones: totalCount,
      completedMilestones: completedList.length,
      inProgressMilestones: inProgressList.length,
      upcomingMilestones: upcomingList.length,
      completionRate: compRate,
      completedList: completedList,
      inProgressList: inProgressList,
      upcomingList: upcomingList,
      insights: insights,
    );
  }
}
