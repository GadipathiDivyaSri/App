import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/pricing_screen.dart';

void showUpgradeProModal(
  BuildContext context, {
  required String featureTitle,
  required String limitExplanation,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppTheme.darkCardBg : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Crown Icon Glow
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF0D5CE5).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF0D5CE5),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Upgrade to Pro for ₹49',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            limitExplanation,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Benefits List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2B3D) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.darkCardBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildProBenefitRow(Icons.all_inclusive_rounded, 'Unlimited Habits & Subject Roadmaps'),
                const SizedBox(height: 10),
                _buildProBenefitRow(Icons.schedule_rounded, 'Full Priority Matrix & Custom Deadlines'),
                const SizedBox(height: 10),
                _buildProBenefitRow(Icons.account_balance_wallet_outlined, 'Full Finance & Expense Ledger'),
                const SizedBox(height: 10),
                _buildProBenefitRow(Icons.block_rounded, '100% Ad-Free Focus Experience'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upgrade Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5CE5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PricingScreen(),
                  ),
                );
              },
              child: const Text(
                'Get Pro for ₹49/month',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _buildProBenefitRow(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xFF0D5CE5)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
