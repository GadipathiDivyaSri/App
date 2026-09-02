import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../models/models.dart';
import '../models/analytics_models.dart';
import '../providers/app_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/pro_feature_guard.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics/analytics_tab_nav.dart';
import '../widgets/analytics/analytics_date_filter_bar.dart';
import '../widgets/analytics/overview_tab_view.dart';
import '../widgets/analytics/habits_tab_view.dart';
import '../widgets/analytics/studies_tab_view.dart';
import '../widgets/analytics/expenses_tab_view.dart';
import '../widgets/analytics/goals_tab_view.dart';
import '../widgets/analytics/milestones_tab_view.dart';
import 'habit_tracker_screen.dart';
import 'academic_planner_screen.dart';
import 'expense_tracker_screen.dart';
import 'career_roadmap_screen.dart';

/// Complete, Modern, Premium Analytics Module for WrindhaOS
/// 
/// 6 Dedicated Sections:
/// 1. Overview
/// 2. Habits
/// 3. Studies
/// 4. Expenses
/// 5. Goals
/// 6. Milestones
/// 
/// Dynamic date range filtering:
/// - This Week
/// - This Month
/// - Last Month
/// - Custom Range
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTabIndex = 0;
  AnalyticsDateRangeType _selectedDateRangeType = AnalyticsDateRangeType.thisWeek;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  void _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? now.subtract(const Duration(days: 30)),
        end: _customEndDate ?? now,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRangeType = AnalyticsDateRangeType.custom;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;

    // Build the active date period
    final period = DateRangePeriod.fromType(
      _selectedDateRangeType,
      customStart: _customStartDate,
      customEnd: _customEndDate,
    );

    // Calculate real data across all modules
    final overviewData = AnalyticsService.calculateOverview(
      habits: provider.habits,
      subjects: provider.subjects,
      studyItems: provider.studyItems,
      tasks: provider.tasks,
      expenses: provider.expenses,
      monthlyBudget: provider.monthlyBudget,
      goals: provider.careerRoadmap,
      period: period,
    );

    final habitData = AnalyticsService.calculateHabits(
      habits: provider.habits,
      period: period,
    );

    final studyData = AnalyticsService.calculateStudies(
      subjects: provider.subjects,
      studyItems: provider.studyItems,
      tasks: provider.tasks,
      period: period,
    );

    final expenseData = AnalyticsService.calculateExpenses(
      expenses: provider.expenses,
      monthlyBudget: provider.monthlyBudget,
      period: period,
    );

    final goalData = AnalyticsService.calculateGoals(
      roadmapNodes: provider.careerRoadmap,
    );

    final milestoneData = AnalyticsService.calculateMilestones(
      roadmapNodes: provider.careerRoadmap,
      habits: provider.habits,
      studyItems: provider.studyItems,
    );

    return ProFeatureGuard(
      feature: AppFeature.analytics,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Analytics & Insights',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HORIZONTAL SCROLLABLE TAB BAR
              AnalyticsTabNav(
                selectedIndex: _selectedTabIndex,
                onTabSelected: (idx) => setState(() => _selectedTabIndex = idx),
              ),
              const SizedBox(height: 16),

              // 2. DYNAMIC DATE RANGE FILTER BAR
              AnalyticsDateFilterBar(
                selectedType: _selectedDateRangeType,
                onSelectType: (type) => setState(() => _selectedDateRangeType = type),
                onCustomDatePicked: _pickCustomDateRange,
              ),
              const SizedBox(height: 20),

              // 3. TAB CONTENT VIEWS
              IndexedStack(
                index: _selectedTabIndex,
                children: [
                  // Tab 0: Overview
                  OverviewTabView(
                    data: overviewData,
                    onNavigateToHabits: () => setState(() => _selectedTabIndex = 1),
                    onNavigateToStudies: () => setState(() => _selectedTabIndex = 2),
                    onNavigateToExpenses: () => setState(() => _selectedTabIndex = 3),
                    onNavigateToGoals: () => setState(() => _selectedTabIndex = 4),
                    onNavigateToMilestones: () => setState(() => _selectedTabIndex = 5),
                  ),

                  // Tab 1: Habits
                  HabitsTabView(
                    data: habitData,
                    onAddHabit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HabitTrackerScreen()),
                      );
                    },
                  ),

                  // Tab 2: Studies
                  StudiesTabView(
                    data: studyData,
                    onAddSubject: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AcademicPlannerScreen()),
                      );
                    },
                  ),

                  // Tab 3: Expenses
                  ExpensesTabView(
                    data: expenseData,
                    onAddExpense: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExpenseTrackerScreen()),
                      );
                    },
                  ),

                  // Tab 4: Goals
                  GoalsTabView(
                    data: goalData,
                    onAddGoal: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CareerRoadmapScreen()),
                      );
                    },
                  ),

                  // Tab 5: Milestones
                  MilestonesTabView(
                    data: milestoneData,
                    onAddMilestone: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CareerRoadmapScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
