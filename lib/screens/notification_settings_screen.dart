import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _focusReminders = true;
  bool _habitStreaks = true;
  bool _goalDeadlines = true;
  bool _dailySummary = false;
  bool _communityUpdates = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notification Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control your flow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage how and when Wrindha OS communicates with you to maintain your peak cognitive clarity.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            // Toggle Cards
            _buildToggleCard(
              context,
              icon: Icons.timer_outlined,
              title: 'Focus Reminders',
              subtitle:
                  "Gentle nudges when it's time to start your scheduled deep work sessions.",
              value: _focusReminders,
              onChanged: (val) => setState(() => _focusReminders = val),
            ),
            const SizedBox(height: 12),

            _buildToggleCard(
              context,
              icon: Icons.local_fire_department_outlined,
              title: 'Habit Streaks',
              subtitle:
                  'Alerts to maintain your momentum when a habit streak is at risk.',
              value: _habitStreaks,
              onChanged: (val) => setState(() => _habitStreaks = val),
            ),
            const SizedBox(height: 12),

            _buildToggleCard(
              context,
              icon: Icons.flag_outlined,
              title: 'Goal Deadlines',
              subtitle:
                  'Stay ahead of your objectives with 24-hour and 1-hour countdown alerts.',
              value: _goalDeadlines,
              onChanged: (val) => setState(() => _goalDeadlines = val),
            ),
            const SizedBox(height: 12),

            _buildToggleCard(
              context,
              icon: Icons.assignment_outlined,
              title: 'Daily Summary',
              subtitle:
                  "A curated evening report of your productivity wins and tomorrow's focus areas.",
              value: _dailySummary,
              onChanged: (val) => setState(() => _dailySummary = val),
            ),
            const SizedBox(height: 12),

            _buildToggleCard(
              context,
              icon: Icons.people_outline_rounded,
              title: 'Community Updates',
              subtitle:
                  'Stay connected with focus challenges and shared insights from high-achievers.',
              value: _communityUpdates,
              onChanged: (val) => setState(() => _communityUpdates = val),
            ),
            const SizedBox(height: 24),

            // OS Alert Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFF0D5CE5), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'System notifications must also be enabled in your OS settings to receive these alerts.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontFamily: 'monospace',
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0D5CE5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0D5CE5), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? const Color(0xFF0D5CE5) : Colors.transparent,
                border: Border.all(
                  color: value ? const Color(0xFF0D5CE5) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.circle, size: 14, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
