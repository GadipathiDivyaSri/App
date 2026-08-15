import 'package:flutter/material.dart';

class GoalAchievedScreen extends StatelessWidget {
  final String goalTitle;
  final String timeTaken;
  final String difficulty;

  const GoalAchievedScreen({
    super.key,
    this.goalTitle = 'Complete React Module',
    this.timeTaken = '12 Days',
    this.difficulty = 'Medium',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Confetti & Celebration Badge Graphic
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D5CE5).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D5CE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFF0D5CE5),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Goal Achieved!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "You've completed ",
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF64748B),
                  ),
                  children: [
                    TextSpan(
                      text: '"$goalTitle"',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D5CE5),
                      ),
                    ),
                    const TextSpan(
                      text: '. Your dedication is paying off!',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Metric Card 1: TIME TAKEN
              _buildMetricCard(
                context,
                icon: Icons.access_time_rounded,
                label: 'TIME TAKEN',
                value: timeTaken,
              ),
              const SizedBox(height: 14),

              // Metric Card 2: DIFFICULTY
              _buildMetricCard(
                context,
                icon: Icons.speed_rounded,
                label: 'DIFFICULTY',
                value: difficulty,
              ),

              const Spacer(),

              // Back to Dashboard Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5CE5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Back to Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // View History Link
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'View History',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
