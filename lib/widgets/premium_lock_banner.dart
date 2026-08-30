import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pro_upgrade_dialog.dart';

/// Reusable Premium Lock Banner Component for WrindhaOS
/// 
/// Used across locked features (Analytics, Expense Tracker, Eisenhower Matrix,
/// Journal, Career Roadmap, Advanced Studies) to display a consistent, elegant
/// locked state banner with a clear upgrade CTA that triggers [ProUpgradeDialog].
class PremiumLockBanner extends StatelessWidget {
  final String featureName;
  final String description;
  final bool compact;

  const PremiumLockBanner({
    super.key,
    required this.featureName,
    this.description = 'Upgrade to WrindhaOS Pro to unlock full access and advanced insights.',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2418) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF59E0B).withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, size: 20, color: Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🔒 $featureName is a Pro Feature',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF92400E),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ProUpgradeDialog.show(
                  context,
                  featureName: featureName,
                  title: 'Unlock $featureName Pro',
                  description: description,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5CE5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E202E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkCardBorder : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0D5CE5).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF0D5CE5),
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '🔒 $featureName (Pro Feature)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                ProUpgradeDialog.show(
                  context,
                  featureName: featureName,
                  title: 'Unlock $featureName Pro',
                  description: description,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5CE5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Unlock Pro Feature',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
