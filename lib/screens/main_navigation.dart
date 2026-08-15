import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFEEF2FF),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left Tab: To-Do
            _buildNavItem(
              index: 0,
              icon: Icons.format_list_bulleted_rounded,
              label: 'To-Do',
            ),
            // Center Tab: Home (Prominent Circle)
            _buildNavItem(
              index: 1,
              icon: Icons.home_filled,
              isCenter: true,
              label: 'Home',
            ),
            // Right Tab: Profile
            _buildNavItem(
              index: 2,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
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
  }) {
    final isSelected = _currentIndex == index;
    final displayIcon = (isSelected && activeIcon != null) ? activeIcon : icon;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
        child: isCenter
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D5CE5),
                  shape: BoxShape.circle,
                ),
                child: Icon(displayIcon, color: Colors.white, size: 24),
              )
            : Icon(
                displayIcon,
                size: 26,
                color: isSelected
                    ? const Color(0xFF0D5CE5)
                    : const Color(0xFF64748B),
              ),
      ),
    );
  }
}
