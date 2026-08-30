import 'package:flutter/material.dart';
import '../config/subscription_config.dart';
import '../screens/pricing_screen.dart';

/// Reusable Pro Upgrade Dialog for WrindhaOS Free vs Pro limits & locked feature gates.
class ProUpgradeDialog extends StatelessWidget {
  final String title;
  final String description;
  final String primaryButtonText;
  final String secondaryButtonText;
  final IconData icon;
  final VoidCallback? onUpgrade;

  const ProUpgradeDialog({
    super.key,
    required this.title,
    required this.description,
    this.primaryButtonText = 'Upgrade to Pro',
    this.secondaryButtonText = 'Maybe Later',
    this.icon = Icons.workspace_premium_rounded,
    this.onUpgrade,
  });

  /// Displays the dialog modally
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    String primaryButtonText = 'Upgrade to Pro',
    String secondaryButtonText = 'Maybe Later',
    IconData icon = Icons.workspace_premium_rounded,
    VoidCallback? onUpgrade,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ProUpgradeDialog(
        title: title,
        description: description,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        icon: icon,
        onUpgrade: onUpgrade,
      ),
    );
  }

  /// Specialized dialog for reaching the Free Habit Limit (Max 2 Habits)
  static Future<void> showHabitLimitDialog(BuildContext context) {
    return show(
      context,
      title: 'Unlock Unlimited Habits',
      description:
          "You've reached the Free plan limit of 2 habits. Upgrade to WrindhaOS Pro to create and track unlimited habits.",
      icon: Icons.track_changes_rounded,
    );
  }

  /// Specialized dialog for reaching the Free Subject Limit (Max 2 Subjects)
  static Future<void> showSubjectLimitDialog(BuildContext context) {
    return show(
      context,
      title: 'Unlock Unlimited Subjects',
      description:
          "You've reached the Free plan limit of 2 subjects. Upgrade to WrindhaOS Pro to manage unlimited subjects and organize your complete learning journey.",
      icon: Icons.menu_book_rounded,
    );
  }

  /// Specialized dialog for locked Pro-only features
  static Future<void> showFeatureLockedDialog(BuildContext context, AppFeature feature) {
    return show(
      context,
      title: 'Unlock ${feature.displayName}',
      description:
          '${feature.displayName} is an advanced feature available exclusively on WrindhaOS Pro. Upgrade now to unlock full access.',
      icon: feature.icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0D5CE5);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 10,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Premium Icon Badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 34,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pro Tag Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 14, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'WRINDHAOS PRO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 28),

            // Primary Button: Upgrade to Pro
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onUpgrade != null) {
                    onUpgrade!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PricingScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  primaryButtonText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Button: Maybe Later
            SizedBox(
              width: double.infinity,
              height: 42,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  secondaryButtonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
