import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/subscription_config.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Dedicated WrindhaOS Pro Plans Screen
/// 
/// Presents a clear, modern, side-by-side / stacked plan comparison between:
/// - FREE PLAN: Unlimited To-Do List, Calendar, Up to 2 Habits, Up to 2 Subjects
/// - PRO PLAN: Everything in Free + Unlimited Habits, Unlimited Subjects, Goal Management,
///             Priority Matrix, Eisenhower Matrix, Expense Tracker, Notes,
///             Achieved Milestones, Career Roadmap, Focus Timer, Analytics & Insights
///
/// Designed ready for Google Play Billing (in_app_purchase) integration.
class ProPlansScreen extends StatefulWidget {
  const ProPlansScreen({super.key});

  @override
  State<ProPlansScreen> createState() => _ProPlansScreenState();
}

class _ProPlansScreenState extends State<ProPlansScreen> {
  bool _isProcessing = false;

  /// Placeholder payment handler ready for future Google Play Billing integration
  void _handleUpgradeToPro(BuildContext context) async {
    setState(() => _isProcessing = true);

    // Simulate connection check / placeholder handler
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _isProcessing = false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5CE5).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.store_mall_directory_rounded,
                  color: Color(0xFF0D5CE5),
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Google Play Billing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'In-App Subscription integration is prepared for production deployment. You can test Pro access immediately with instant preview.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final provider = Provider.of<AppProvider>(context, listen: false);
                    provider.upgradeToPremium();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 WrindhaOS Pro unlocked successfully!'),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5CE5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Unlock Pro Preview (Developer Mode)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Dismiss', style: TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final isPro = provider.user.isPremium;

    final primaryColor = const Color(0xFF0D5CE5);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'WrindhaOS Plans',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hero Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'SUPERCHARGE YOUR PRODUCTIVITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Simple & Transparent Plans',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start free with essential tools, or upgrade to Pro to unlock unlimited workflows and advanced analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.45, color: textSecondary),
            ),
            const SizedBox(height: 24),

            // =================================================================
            // 1. FREE PLAN CARD
            // =================================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FREE PLAN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹0',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (!isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: const Text(
                            'CURRENT PLAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Essential tools to kickstart your daily routines:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  const SizedBox(height: 12),

                  _buildFeatureCheckItem('Unlimited To-Do List', isIncluded: true, isDark: isDark),
                  _buildFeatureCheckItem('Productivity Calendar', isIncluded: true, isDark: isDark),
                  _buildFeatureCheckItem('Up to 2 Active Habits', isIncluded: true, isDark: isDark),
                  _buildFeatureCheckItem('Up to 2 Academic Subjects', isIncluded: true, isDark: isDark),
                  _buildFeatureCheckItem('Advanced Matrices & Analytics', isIncluded: false, isDark: isDark),
                  _buildFeatureCheckItem('Goal Pyramid & Career Nodes', isIncluded: false, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // =================================================================
            // 2. PRO PLAN CARD (HERO CARD)
            // =================================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF132F5C), const Color(0xFF0F172A)]
                      : [const Color(0xFFEFF6FF), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: primaryColor.withOpacity(0.6), width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'WRINDHAOS PRO',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'RECOMMENDED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹49',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ month',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          ),
                          child: const Text(
                            'ACTIVE PRO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Everything in Free, plus complete power tools:',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 14),

                  // Pro Features List
                  _buildProCheckItem('Unlimited Habits & Streak Tracking', isDark),
                  _buildProCheckItem('Unlimited Academic Subjects & Units', isDark),
                  _buildProCheckItem('Goal Pyramid Management', isDark),
                  _buildProCheckItem('Priority Matrix (Urgent vs Important)', isDark),
                  _buildProCheckItem('Eisenhower Quadrant Matrix', isDark),
                  _buildProCheckItem('Expense & Student Budget Tracker', isDark),
                  _buildProCheckItem('Notes & Daily Journaling Logs', isDark),
                  _buildProCheckItem('Achieved Milestones Archive', isDark),
                  _buildProCheckItem('Interactive Career Node Roadmap', isDark),
                  _buildProCheckItem('Deep Focus Timer (Pomodoro & Stopwatch)', isDark),
                  _buildProCheckItem('Full Productivity Analytics & Insights', isDark),

                  const SizedBox(height: 24),

                  // Upgrade to Pro Primary CTA
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isPro ? null : () => _handleUpgradeToPro(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              isPro ? 'You are on Pro' : 'Upgrade to Pro',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCheckItem(String title, {required bool isIncluded, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Icon(
            isIncluded ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: isIncluded
                ? const Color(0xFF10B981)
                : (isDark ? Colors.white24 : Colors.black26),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isIncluded ? FontWeight.w600 : FontWeight.w500,
                color: isIncluded
                    ? (isDark ? Colors.white : const Color(0xFF1E293B))
                    : (isDark ? Colors.white38 : Colors.black38),
                decoration: isIncluded ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProCheckItem(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Color(0xFF0D5CE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
