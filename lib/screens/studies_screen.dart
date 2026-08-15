import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'subject_planner_screen.dart';
import 'goal_pyramid_screen.dart';
import 'focus_timer_screen.dart';

class StudiesScreen extends StatelessWidget {
  const StudiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Studies'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            _buildStudyCard(
              context,
              icon: Icons.menu_book_rounded,
              title: 'Subject planner',
              subtitle: 'Manage subjects, units & topics',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubjectPlannerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildStudyCard(
              context,
              icon: Icons.calendar_today_rounded,
              title: 'time table',
              subtitle: 'Weekly schedule',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CalendarScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildStudyCard(
              context,
              icon: Icons.timer_outlined,
              title: 'focus timer',
              subtitle: 'Deep work sessions & stopwatch',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FocusTimerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildStudyCard(
              context,
              icon: Icons.flag_outlined,
              title: 'Goals Hierarchy',
              subtitle: 'Pyramid structure (Short, Medium, Long)',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GoalPyramidScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D5CE5).withOpacity(0.1),
              ),
              child: Icon(icon, color: const Color(0xFF0D5CE5), size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8), size: 22),
          ],
        ),
      ),
    );
  }
}
