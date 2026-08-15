import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Personal Growth'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            // Top Blue Banner "Build Your Future"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build Your Future',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Track your daily progress and master your habits to reach peak productivity.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
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

            _buildMenuCard(
              context,
              category: 'CAREER ROADMAP',
              title: 'Track your Milestones',
              icon: Icons.flag_outlined,
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

            _buildMenuCard(
              context,
              category: 'KNOWLEDGE HUB',
              title: 'Journal',
              icon: Icons.book_outlined,
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
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0D5CE5).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF0D5CE5), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
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
