import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/upgrade_pro_modal.dart';
import '../theme/app_theme.dart';
import 'habit_tracker_screen.dart';
import 'expense_tracker_screen.dart';
import 'milestones_screen.dart';
import 'organize_matrix_screen.dart';
import 'notes_screen.dart';

class PersonalGrowthScreen extends StatelessWidget {
  const PersonalGrowthScreen({super.key});

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
            // Top Pastel / Dark Banner (Refer to Image 2)
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

            _buildMenuCard(
              context,
              category: 'FINANCIAL HEALTH',
              title: 'Track your Expenses',
              icon: Icons.account_balance_wallet_outlined,
              isDark: isDark,
              isLocked: !isPremium,
              onTap: () {
                if (!isPremium) {
                  showUpgradeProModal(
                    context,
                    featureTitle: 'Expense Tracker',
                    limitExplanation: 'Personal Finance Tracking & Expense Ledger are exclusive to Pro members. Upgrade for ₹49/month to unlock!',
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExpenseTrackerScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 14),

            _buildMenuCard(
              context,
              category: 'CAREER ROADMAP',
              title: 'Track your Milestones',
              icon: Icons.flag_outlined,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MilestonesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            _buildMenuCard(
              context,
              category: 'ORGANIZATION',
              title: 'Organize your tasks',
              icon: Icons.format_list_bulleted_rounded,
              isDark: isDark,
              isLocked: !isPremium,
              onTap: () {
                if (!isPremium) {
                  showUpgradeProModal(
                    context,
                    featureTitle: 'Organize Matrix',
                    limitExplanation: 'Eisenhower Quadrant Matrix & Task Triage are exclusive to Pro members. Upgrade for ₹49/month to unlock!',
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrganizeMatrixScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 14),

            _buildMenuCard(
              context,
              category: 'KNOWLEDGE HUB',
              title: 'Journal',
              icon: Icons.book_outlined,
              isDark: isDark,
              isLocked: !isPremium,
              onTap: () {
                if (!isPremium) {
                  showUpgradeProModal(
                    context,
                    featureTitle: 'Journal & Notes',
                    limitExplanation: 'Daily Productivity Journal & Reflection Logs are exclusive to Pro members. Upgrade for ₹49/month to unlock!',
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotesScreen(),
                    ),
                  );
                }
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
