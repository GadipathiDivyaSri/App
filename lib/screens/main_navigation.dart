import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'todo_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // Default to Home (Center tab)

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      TodoScreen(onNavigateToHome: () {
        setState(() => _currentIndex = 1);
      }),
      HomeScreen(onTabChange: (index) {
        setState(() => _currentIndex = index);
      }),
      ProfileScreen(onNavigateToHome: () {
        setState(() => _currentIndex = 1);
      }),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
              // Left Tab: Menu / To-Do
              _buildNavItem(
                index: 0,
                icon: Icons.menu_rounded,
                activeIcon: Icons.menu_rounded,
                label: 'Menu',
                isDark: isDark,
              ),
              // Center Tab: Home (Floating round button)
              _buildNavItem(
                index: 1,
                icon: Icons.home_rounded,
                isCenter: true,
                label: 'Home',
                isDark: isDark,
              ),
              // Right Tab: Profile
              _buildNavItem(
                index: 2,
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
    bool isCenter = false,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final displayIcon = (isSelected && activeIcon != null) ? activeIcon : icon;

    final activeColor = isDark ? AppTheme.darkIconGlow : AppTheme.lightPrimary;
    final inactiveColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCenter)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(displayIcon, color: Colors.white, size: 26),
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
