import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../config/subscription_config.dart';
import '../widgets/pro_feature_guard.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../widgets/upgrade_pro_modal.dart';
import '../theme/app_theme.dart';
import 'personal_growth_screen.dart';
import 'career_screen.dart';
import 'studies_screen.dart';
import 'calendar_screen.dart';
import 'priority_matrix_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Wrindha',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: 'OS',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkIconGlow : AppTheme.lightPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6 Module Grid Dashboard Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.98,
                  children: [
                    // 1. Personal Growth
                    _buildModuleCard(
                      context,
                      isDark: isDark,
                      icon: Icons.spa_outlined,
                      title: 'Personal\nGrowth',
                      subtitle: 'Habits & Streaks',
                      lightCardBg: AppTheme.pastelPersonalGrowth,
                      lightIconContainerColor: const Color(0xFF4A9B65),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PersonalGrowthScreen(),
                          ),
                        );
                      },
                    ),

                    // 2. Career (PRO ONLY: AppFeature.careerRoadmap & AppFeature.goals)
                    _buildModuleCard(
                      context,
                      isDark: isDark,
                      icon: Icons.work_outline_rounded,
                      title: 'Career',
                      subtitle: 'Pathways & Goals',
                      lightCardBg: AppTheme.pastelCareer,
                      lightIconContainerColor: AppTheme.pastelCareerIcon,
                      isLocked: !provider.hasAccess(AppFeature.careerRoadmap),
                      onTap: () {
                        ProFeatureGuard.navigate(
                          context,
                          feature: AppFeature.careerRoadmap,
                          builder: () => const CareerScreen(),
                        );
                      },
                    ),

                    // 3. Studies
                    _buildModuleCard(
                      context,
                      isDark: isDark,
                      icon: Icons.school_outlined,
                      title: 'Studies',
                      subtitle: 'Subplanner & Focus',
                      lightCardBg: AppTheme.pastelStudies,
                      lightIconContainerColor: AppTheme.pastelStudiesIcon,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudiesScreen(),
                          ),
                        );
                      },
                    ),

                    // 4. Calendar
                    _buildModuleCard(
                      context,
                      isDark: isDark,
                      icon: Icons.calendar_today_outlined,
                      title: 'Calendar',
                      subtitle: 'View Schedule',
                      lightCardBg: AppTheme.pastelCalendar,
                      lightIconContainerColor: AppTheme.pastelCalendarIcon,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CalendarScreen(),
                          ),
                        );
                      },
                    ),

                    // 5. Priority Matrix (PRO ONLY: AppFeature.priorityMatrix)
                    _buildModuleCard(
                      context,
                      isDark: isDark,
                      icon: Icons.flag_outlined,
                      title: 'Priority',
                      subtitle: 'Priority Matrix',
                      lightCardBg: AppTheme.pastelPriority,
                      lightIconContainerColor: AppTheme.pastelPriorityIcon,
                      isLocked: !provider.hasAccess(AppFeature.priorityMatrix),
                      onTap: () {
                        ProFeatureGuard.navigate(
                          context,
                          feature: AppFeature.priorityMatrix,
                          builder: () => const PriorityMatrixScreen(),
                        );
                      },
                    ),

                    // 6. Analytics (PRO ONLY: AppFeature.analytics)
                    _buildModuleCard(
                      context,
                      isDark: isDark,
                      icon: Icons.bar_chart_rounded,
                      title: 'Analytics',
                      subtitle: 'Track Progress',
                      lightCardBg: AppTheme.pastelAnalytics,
                      lightIconContainerColor: AppTheme.pastelAnalyticsIcon,
                      isLocked: !provider.hasAccess(AppFeature.analytics),
                      onTap: () {
                        ProFeatureGuard.navigate(
                          context,
                          feature: AppFeature.analytics,
                          builder: () => const AnalyticsScreen(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color lightCardBg,
    required Color lightIconContainerColor,
    bool isLocked = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : lightCardBg,
          borderRadius: BorderRadius.circular(22),
          border: isDark
              ? Border.all(color: AppTheme.darkCardBorder, width: 1)
              : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Squircle Icon & Lock / Chevron Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkIconBg
                        : lightIconContainerColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: lightIconContainerColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isDark ? AppTheme.darkIconGlow : Colors.white,
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
                    size: 20,
                    color: isDark ? const Color(0xFF4C658A) : const Color(0x662D2622),
                  ),
              ],
            ),

            // Bottom Section: Title & Subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
