import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/upgrade_pro_modal.dart';
import '../theme/app_theme.dart';
import 'calendar_screen.dart';
import 'subject_planner_screen.dart';
import 'goal_pyramid_screen.dart';
import 'focus_timer_screen.dart';

class StudiesScreen extends StatelessWidget {
  const StudiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = Provider.of<AppProvider>(context).user.isPremium;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Studies & Focus',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // Top Pastel / Dark Banner (Refer to Image 2)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.pastelStudies,
                borderRadius: BorderRadius.circular(22),
                border: isDark
                    ? Border.all(color: AppTheme.darkCardBorder, width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkIconBg
                          : AppTheme.pastelStudiesIcon,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      color: isDark ? AppTheme.darkIconGlow : Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Studies Dashboard',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Subplanner, timetable & deep focus 📚',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildStudyCard(
              context,
              icon: Icons.menu_book_rounded,
              title: 'Subject Planner',
              subtitle: 'Manage subjects, units & topics',
              isDark: isDark,
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
              title: 'Timetable',
              subtitle: 'Weekly class schedule & sessions',
              isDark: isDark,
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
              title: 'Focus Timer',
              subtitle: 'Deep work sessions & stopwatch',
              isDark: isDark,
              isLocked: !isPremium,
              onTap: () {
                if (!isPremium) {
                  showUpgradeProModal(
                    context,
                    featureTitle: 'Focus Timer & Centre',
                    limitExplanation: 'Pomodoro Focus Timer, ambient soundscapes, and deep work sessions are exclusive to Pro members. Upgrade for ₹49/month to unlock!',
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FocusTimerScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildStudyCard(
              context,
              icon: Icons.flag_outlined,
              title: 'Goals Hierarchy',
              subtitle: 'Pyramid structure (Short, Medium, Long)',
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GoalPyramidScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
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
    required bool isDark,
    bool isLocked = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDark
              ? Border.all(color: AppTheme.darkCardBorder, width: 1)
              : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark
                    ? AppTheme.darkIconBg
                    : AppTheme.pastelStudies,
              ),
              child: Icon(
                icon,
                color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelStudiesIcon,
                size: 24,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD97706),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF4C658A) : const Color(0xFF8D827A),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
