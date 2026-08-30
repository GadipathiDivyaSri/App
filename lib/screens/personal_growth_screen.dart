import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../providers/app_provider.dart';
import '../widgets/pro_feature_guard.dart';
import '../widgets/pro_upgrade_dialog.dart';
import '../widgets/upgrade_pro_modal.dart';
import '../theme/app_theme.dart';
import 'habit_tracker_screen.dart';
import 'expense_tracker_screen.dart';
import 'career_roadmap_screen.dart';
import 'organize_matrix_screen.dart';
import 'notes_screen.dart';

class PersonalGrowthScreen extends StatelessWidget {
  const PersonalGrowthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);

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
          'Personal Growth',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            // Top Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.pastelPersonalGrowth,
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
                          : AppTheme.pastelPersonalGrowthIcon,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.spa_outlined,
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
                          'Personal Growth',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Grow better, every day 🌿',
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
            const SizedBox(height: 24),

            // Navigation List Cards
            // 1. Habits (Free Plan Allowed up to 2, Pro Unlimited)
            _buildMenuCard(
              context,
              category: 'SELF IMPROVEMENT',
              title: 'Track your Habits',
              icon: Icons.swap_horiz_rounded,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HabitTrackerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // 2. Expenses (Pro Only)
            _buildMenuCard(
              context,
              category: 'FINANCIAL HEALTH',
              title: 'Track your Expenses',
              icon: Icons.account_balance_wallet_outlined,
              isDark: isDark,
              isLocked: !provider.hasAccess(AppFeature.expenseTracker),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExpenseTrackerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // 3. Career Roadmap (Pro Only)
            _buildMenuCard(
              context,
              category: 'CAREER ROADMAP',
              title: 'Career Roadmap & Growth',
              icon: Icons.alt_route_rounded,
              isDark: isDark,
              isLocked: !provider.hasAccess(AppFeature.careerRoadmap),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CareerRoadmapScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // 4. Organize Matrix (Pro Only)
            _buildMenuCard(
              context,
              category: 'ORGANIZATION',
              title: 'Organize your tasks',
              icon: Icons.format_list_bulleted_rounded,
              isDark: isDark,
              isLocked: !provider.hasAccess(AppFeature.eisenhowerMatrix),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrganizeMatrixScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // 5. Journal & Notes (Pro Only)
            _buildMenuCard(
              context,
              category: 'KNOWLEDGE HUB',
              title: 'Journal & Notes',
              icon: Icons.book_outlined,
              isDark: isDark,
              isLocked: !provider.hasAccess(AppFeature.notes),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotesScreen(),
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

  Widget _buildMenuCard(
    BuildContext context, {
    required String category,
    required String title,
    required IconData icon,
    required bool isDark,
    bool isLocked = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(18),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkIconBg
                    : AppTheme.pastelPersonalGrowth,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDark ? AppTheme.darkIconGlow : AppTheme.pastelPersonalGrowthIcon,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
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
