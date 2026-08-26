import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Pricing & Plans Screen for WrindhaOS
/// 
/// Compares:
/// - Free Plan (₹0): 2 Habits, 2 Subjects, To-Do List, Calendar
/// - Pro Plan (₹49/month): Unlimited Habits, Subjects, Expense Tracker, Eisenhower, Journal, Career Roadmap, Analytics
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _isProcessing = false;

  void _handleUpgrade() async {
    setState(() => _isProcessing = true);
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Simulate payment / instant unlock
    await Future.delayed(const Duration(milliseconds: 600));
    provider.upgradeToPremium();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Welcome to WrindhaOS Pro! All features unlocked.'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final user = provider.user;
    final isPremium = user.isPremium;
    final discountPercent = user.activeDiscountPercent;

    const double basePrice = 59.0;
    final double discountAmount = (basePrice * discountPercent) / 100.0;
    final double finalPrice = basePrice - discountAmount;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pricing & Plans',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            Text(
              'Choose Your Plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Simple and transparent pricing for students and professionals.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.4, color: textSecondary),
            ),
            const SizedBox(height: 24),

            // Card 1: FREE PLAN (₹0)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight),
                boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FREE',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      if (!isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkIconBg : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'CURRENT PLAN',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: textSecondary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: '₹0',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: textPrimary),
                      children: [
                        TextSpan(
                          text: ' / forever',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildFeatureRow('2 Habits', isIncluded: true),
                  _buildFeatureRow('2 Subjects', isIncluded: true),
                  _buildFeatureRow('To-Do List', isIncluded: true),
                  _buildFeatureRow('Calendar', isIncluded: true),
                  _buildFeatureRow('Expense Tracker', isIncluded: false),
                  _buildFeatureRow('Eisenhower Matrix', isIncluded: false),
                  _buildFeatureRow('Personal Journal / Diary', isIncluded: false),
                  _buildFeatureRow('Career Roadmap', isIncluded: false),
                  _buildFeatureRow('Multi-Period Analytics', isIncluded: false),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: isPremium ? () {} : null,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(!isPremium ? 'Current Plan' : 'Downgrade to Free'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card 2: PRO PLAN (₹49/month)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1F30) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF0D5CE5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D5CE5).withOpacity(0.12),
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
                          const Text(
                            'PRO',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0D5CE5)),
                          ),
                          if (isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'ACTIVE SUBSCRIBER',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF10B981)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          text: '₹49',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary),
                          children: [
                            TextSpan(
                              text: ' / month',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildFeatureRow('Unlimited Habits & Streaks', isIncluded: true),
                      _buildFeatureRow('Unlimited Subjects & Syllabi', isIncluded: true),
                      _buildFeatureRow('Full To-Do List & Priority Scheduling', isIncluded: true),
                      _buildFeatureRow('Full Calendar Scheduling', isIncluded: true),
                      _buildFeatureRow('Expense Tracker & Budget Ledger', isIncluded: true),
                      _buildFeatureRow('Eisenhower Matrix Organization', isIncluded: true),
                      _buildFeatureRow('Encrypted Personal Journal / Diary', isIncluded: true),
                      _buildFeatureRow('Floating Career Roadmap', isIncluded: true),
                      _buildFeatureRow('Multi-Period Analytics (10 Days, Week, Month, Year)', isIncluded: true),
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isPremium || _isProcessing ? null : _handleUpgrade,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D5CE5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(
                                  isPremium ? 'Already Subscribed' : 'Upgrade to Pro',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -12,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D5CE5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D5CE5).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'RECOMMENDED',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text, {required bool isIncluded}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(
            isIncluded ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 16,
            color: isIncluded ? const Color(0xFF10B981) : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isIncluded ? FontWeight.w600 : FontWeight.normal,
                color: isIncluded ? null : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
