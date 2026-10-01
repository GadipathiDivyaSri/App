import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/upgrade_pro_modal.dart';
import 'home_screen.dart';
import 'todo_screen.dart';
import 'profile_screen.dart';
import '../features/smart_assistant/smart_assistant_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // Default to Home

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      HomeScreen(onTabChange: (index) {
        setState(() => _currentIndex = index);
      }),
      TodoScreen(onNavigateToHome: () {
        setState(() => _currentIndex = 0);
      }),
      const SmartAssistantScreen(),
      ProfileScreen(onNavigateToHome: () {
        setState(() => _currentIndex = 0);
      }),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkNavBg : AppTheme.lightNavBg,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: isDark
              ? const Border(top: BorderSide(color: Color(0x1A2A85FF), width: 1))
              : null,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home Tab
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isDark: isDark,
              ),
              // 2. To-Do Tab
              _buildNavItem(
                index: 1,
                icon: Icons.format_list_bulleted_rounded,
                activeIcon: Icons.task_alt_rounded,
                label: 'To Do',
                isDark: isDark,
              ),
              // 3. AI Assistant Tab (Robot Icon - PRO EXCLUSIVE)
              _buildNavItem(
                index: 2,
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy_rounded,
                isAssistant: true,
                label: 'Assistant',
                isDark: isDark,
              ),
              // 4. Profile Tab
              _buildNavItem(
                index: 3,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    IconData? activeIcon,
    bool isAssistant = false,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final displayIcon = (isSelected && activeIcon != null) ? activeIcon : icon;

    final activeColor = isDark ? AppTheme.darkIconGlow : AppTheme.lightPrimary;
    final inactiveColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: () {
        if (index == 2) {
          final provider = Provider.of<AppProvider>(context, listen: false);
          if (!provider.user.isPremium && provider.currentPlan != SubscriptionPlanType.pro) {
            showUpgradeProModal(
              context,
              featureTitle: 'Wrindha AI Assistant',
              limitExplanation: 'The Wrindha AI Smart Assistant is an advanced automated feature available exclusively for WrindhaOS Pro subscribers.',
            );
            return;
          }
        }
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAssistant)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0052FF)
                    : (isDark ? const Color(0xFF1E2235) : const Color(0xFFEEF2FF)),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0052FF).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0052FF)
                      : (isDark ? const Color(0x332A85FF) : const Color(0xFFCBD5E1)),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    displayIcon,
                    size: 18,
                    color: isSelected ? Colors.white : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF0052FF)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF0052FF)),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Icon(
              displayIcon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
