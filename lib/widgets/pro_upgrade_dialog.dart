import 'package:flutter/material.dart';
import '../config/subscription_config.dart';
import '../screens/pro_plans_screen.dart';

/// Reusable WrindhaOS Pro Upgrade Dialog
/// 
/// Accepts:
/// - [featureName] or [feature] (AppFeature enum)
/// - [title] (e.g. 'Unlock Analytics & Insights')
/// - [description] (e.g. 'Understand your productivity, track your progress, and discover patterns that help you improve.')
/// - Optional [icon] (e.g. Icons.insights_rounded)
/// - Optional [onUpgrade] callback
/// 
/// Dynamically updates title, description, and icon depending on the clicked locked feature.
class ProUpgradeDialog extends StatelessWidget {
  final String? featureName;
  final String title;
  final String description;
  final IconData? icon;
  final String primaryButtonText;
  final String secondaryButtonText;
  final VoidCallback? onUpgrade;

  const ProUpgradeDialog({
    super.key,
    this.featureName,
    required this.title,
    required this.description,
    this.icon = Icons.workspace_premium_rounded,
    this.primaryButtonText = 'Upgrade to Pro',
    this.secondaryButtonText = 'Maybe Later',
    this.onUpgrade,
  });

  /// Factory constructor to generate dialog directly from an [AppFeature]
  factory ProUpgradeDialog.fromFeature({
    Key? key,
    required AppFeature feature,
    VoidCallback? onUpgrade,
  }) {
    return ProUpgradeDialog(
      key: key,
      featureName: feature.displayName,
      title: feature.unlockTitle,
      description: feature.benefitDescription,
      icon: feature.icon,
      onUpgrade: onUpgrade,
    );
  }

  /// Displays the dialog modally with dynamic parameters
  static Future<void> show(
    BuildContext context, {
    String? featureName,
    required String title,
    required String description,
    IconData? icon,
    String primaryButtonText = 'Upgrade to Pro',
    String secondaryButtonText = 'Maybe Later',
    VoidCallback? onUpgrade,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ProUpgradeDialog(
        featureName: featureName,
        title: title,
        description: description,
        icon: icon ?? Icons.workspace_premium_rounded,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onUpgrade: onUpgrade,
      ),
    );
  }

  /// Displays the dialog modally based on an [AppFeature]
  static Future<void> showFeatureLockedDialog(
    BuildContext context,
    AppFeature feature, {
    VoidCallback? onUpgrade,
  }) {
    return show(
      context,
      featureName: feature.displayName,
      title: feature.unlockTitle,
      description: feature.benefitDescription,
      icon: feature.icon,
      onUpgrade: onUpgrade,
    );
  }

  /// Specialized shortcut for Free Habit Limit (Max 2 Habits)
  static Future<void> showHabitLimitDialog(BuildContext context, {VoidCallback? onUpgrade}) {
    return showFeatureLockedDialog(context, AppFeature.habits, onUpgrade: onUpgrade);
  }

  /// Specialized shortcut for Free Subject Limit (Max 2 Subjects)
  static Future<void> showSubjectLimitDialog(BuildContext context, {VoidCallback? onUpgrade}) {
    return showFeatureLockedDialog(context, AppFeature.subjects, onUpgrade: onUpgrade);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0D5CE5);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final displayIcon = icon ?? Icons.workspace_premium_rounded;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 12,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Premium Icon Glow Container
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  displayIcon,
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

            // Dynamic Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),

            // Dynamic Benefit Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.48,
                color: textSecondary,
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
                      MaterialPageRoute(builder: (_) => const ProPlansScreen()),
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
                  foregroundColor: textSecondary,
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
