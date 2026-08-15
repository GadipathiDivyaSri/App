import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Analytics & Insights'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Module Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.transparent,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: const Color(0xFF0D5CE5),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Habits'),
                Tab(text: 'Expenses'),
                Tab(text: 'Milestones'),
                Tab(text: 'Studies'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context),
                _buildHabitsAnalyticsTab(context),
                _buildExpensesAnalyticsTab(context),
                _buildMilestonesAnalyticsTab(context),
                _buildStudiesAnalyticsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. OVERVIEW TAB
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);

    final habitStreak = '${provider.user.activeStreak} Days';
    final budgetSavings = '₹${provider.monthlyBudget.toStringAsFixed(0)}';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        Text(
          'Productivity Scorecard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'High-level performance metrics across all active modules.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),

        // Summary Metric Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                context,
                title: 'HABIT STREAK',
                value: habitStreak,
                icon: Icons.local_fire_department_outlined,
                color: const Color(0xFF0D5CE5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricBox(
                context,
                title: 'MONTHLY BUDGET',
                value: budgetSavings,
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                context,
                title: 'TASKS DONE',
                value: '${provider.tasks.where((t) => t.isCompleted).length} / ${provider.tasks.length}',
                icon: Icons.emoji_events_outlined,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricBox(
                context,
                title: 'FOCUS SCORE',
                value: '${provider.user.focusScore} XP',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Overview Chart Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MODULE PERFORMANCE COMPARISON',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: ComparisonBarChartPainter(isDark: isDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. HABIT TRACKER ANALYTICS TAB
  // ---------------------------------------------------------------------------
  Widget _buildHabitsAnalyticsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        Text(
          'Habit Momentum & Consistency',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Track your daily habit completions and 4-week streak trends.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),

        // Bar Graph: Habits with Week
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'WEEKLY HABITS COMPLETED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Avg: 4.8 / day',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D5CE5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: HabitsBarChartPainter(isDark: isDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Line Chart: Streak Trend over 4 Weeks
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '4-WEEK STREAK LINE TREND',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: LineChartPainter(
                    isDark: isDark,
                    points: const [0.4, 0.6, 0.75, 0.92],
                    labels: const ['W1', 'W2', 'W3', 'W4'],
                    lineColor: const Color(0xFF0D5CE5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. EXPENSE TRACKER ANALYTICS TAB
  // ---------------------------------------------------------------------------
  Widget _buildExpensesAnalyticsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        Text(
          'Financial Breakdown & Cashflow',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Category pie chart distribution and monthly spending trends.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),

        // Pie Chart Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CATEGORY SPENDING PIE CHART',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: CustomPaint(
                      painter: ExpensePieChartPainter(),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: const [
                        _LegendItem(color: Color(0xFF0D5CE5), label: 'Food (35%)'),
                        SizedBox(height: 8),
                        _LegendItem(color: Color(0xFF3B82F6), label: 'Shopping (25%)'),
                        SizedBox(height: 8),
                        _LegendItem(color: Color(0xFF60A5FA), label: 'Transport (15%)'),
                        SizedBox(height: 8),
                        _LegendItem(color: Color(0xFF10B981), label: 'Income (25%)'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Line Chart: Weekly & Monthly Distribution
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MONTHLY CASHFLOW & SPENDING LINE CHART',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: LineChartPainter(
                    isDark: isDark,
                    points: const [0.3, 0.7, 0.45, 0.85, 0.6],
                    labels: const ['Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                    lineColor: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. MILESTONES & GOALS ANALYTICS TAB
  // ---------------------------------------------------------------------------
  Widget _buildMilestonesAnalyticsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        Text(
          'Milestones & Goals Progress',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Status pie chart distribution & overall milestone completion score.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),

        // Pie Chart: Achieved vs In Progress vs Not Started
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GOALS STATUS PIE CHART',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: CustomPaint(
                      painter: GoalsPieChartPainter(),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: const [
                        _LegendItem(
                            color: Color(0xFF0D5CE5), label: 'Achieved (40%)'),
                        SizedBox(height: 10),
                        _LegendItem(
                            color: Color(0xFFF59E0B), label: 'In Progress (45%)'),
                        SizedBox(height: 10),
                        _LegendItem(
                            color: Color(0xFFCBD5E1), label: 'Not Started (15%)'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Overall Completion Percentage Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D5CE5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '78%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Milestone Fulfillment Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '5 Achieved • 5 In Progress • 2 Not Started',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. STUDIES ANALYTICS TAB
  // ---------------------------------------------------------------------------
  Widget _buildStudiesAnalyticsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        Text(
          'Academic Study Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Subject-wise completion line chart & study hours distribution.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),

        // Line Chart: Subject Completion Rate Over Time
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SUBJECT COMPLETION RATE OVER TIME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: LineChartPainter(
                    isDark: isDark,
                    points: const [0.35, 0.55, 0.70, 0.88],
                    labels: const ['W1', 'W2', 'W3', 'W4'],
                    lineColor: const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Bar Chart: Subject Study Hours Logged
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SUBJECT STUDY HOURS LOGGED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: StudiesBarChartPainter(isDark: isDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS FOR CHARTS
// =============================================================================

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}

class HabitsBarChartPainter extends CustomPainter {
  final bool isDark;
  HabitsBarChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final values = [4, 5, 3, 6, 5, 4, 6];
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxVal = 6.0;

    final barWidth = 24.0;
    final space = (size.width - (values.length * barWidth)) / (values.length + 1);

    final paint = Paint()..color = const Color(0xFF0D5CE5);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < values.length; i++) {
      final x = space + i * (barWidth + space);
      final heightRatio = values[i] / maxVal;
      final barHeight = (size.height - 30) * heightRatio;
      final y = (size.height - 30) - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);

      // Label
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x + (barWidth - textPainter.width) / 2, size.height - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StudiesBarChartPainter extends CustomPainter {
  final bool isDark;
  StudiesBarChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final values = [14, 18, 16];
    final labels = ['Algebra', 'Physics', 'CS Algo'];
    final maxVal = 20.0;

    final barWidth = 44.0;
    final space = (size.width - (values.length * barWidth)) / (values.length + 1);

    final paint = Paint()..color = const Color(0xFF8B5CF6);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < values.length; i++) {
      final x = space + i * (barWidth + space);
      final heightRatio = values[i] / maxVal;
      final barHeight = (size.height - 30) * heightRatio;
      final y = (size.height - 30) - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, paint);

      // Value label on top
      textPainter.text = TextSpan(
        text: '${values[i]}h',
        style: const TextStyle(
          color: Color(0xFF8B5CF6),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x + (barWidth - textPainter.width) / 2, y - 16));

      // Label below
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x + (barWidth - textPainter.width) / 2, size.height - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ComparisonBarChartPainter extends CustomPainter {
  final bool isDark;
  ComparisonBarChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final values = [0.88, 0.70, 0.78, 0.85];
    final labels = ['Habits', 'Expenses', 'Goals', 'Studies'];
    final colors = [
      const Color(0xFF0D5CE5),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
    ];

    final barWidth = 36.0;
    final space = (size.width - (values.length * barWidth)) / (values.length + 1);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < values.length; i++) {
      final x = space + i * (barWidth + space);
      final barHeight = (size.height - 30) * values[i];
      final y = (size.height - 30) - barHeight;

      final paint = Paint()..color = colors[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, paint);

      // Label
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x + (barWidth - textPainter.width) / 2, size.height - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineChartPainter extends CustomPainter {
  final bool isDark;
  final List<double> points;
  final List<String> labels;
  final Color lineColor;

  LineChartPainter({
    required this.isDark,
    required this.points,
    required this.labels,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final widthStep = size.width / (points.length - 1);
    final chartHeight = size.height - 30;

    final path = Path();
    final dotPaint = Paint()..color = lineColor;
    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final x = i * widthStep;
      final y = chartHeight - (points[i] * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 5, dotPaint);

      // Label below
      if (i < labels.length) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(x - (textPainter.width / 2), size.height - 20));
      }
    }
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ExpensePieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final slices = [
      {'pct': 0.35, 'color': const Color(0xFF0D5CE5)},
      {'pct': 0.25, 'color': const Color(0xFF3B82F6)},
      {'pct': 0.15, 'color': const Color(0xFF60A5FA)},
      {'pct': 0.25, 'color': const Color(0xFF10B981)},
    ];

    double startAngle = -pi / 2;

    for (final s in slices) {
      final sweepAngle = (s['pct'] as double) * 2 * pi;
      final paint = Paint()..color = s['color'] as Color;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoalsPieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final slices = [
      {'pct': 0.40, 'color': const Color(0xFF0D5CE5)},
      {'pct': 0.45, 'color': const Color(0xFFF59E0B)},
      {'pct': 0.15, 'color': const Color(0xFFCBD5E1)},
    ];

    double startAngle = -pi / 2;

    for (final s in slices) {
      final sweepAngle = (s['pct'] as double) * 2 * pi;
      final paint = Paint()..color = s['color'] as Color;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
