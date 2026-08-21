import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _isProcessing = false;

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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pricing & Plans',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            Text(
              'Focus on what matters',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unlock your cognitive clarity with tailored focus plans.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Card 1: Free Plan
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(22),
                border: isDark ? Border.all(color: AppTheme.darkCardBorder, width: 1) : null,
                boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Free',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      if (!isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkIconBg : AppTheme.inputBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'CURRENT PLAN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: '₹0',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkIconGlow : AppTheme.primaryAccent,
                      ),
                      children: [
                        TextSpan(
                          text: '/forever',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildCheckItem('2 Habits trackable daily'),
                  _buildCheckItem('2 Studies active focus'),
                  _buildCheckItem('Standard To-Do list'),
                  _buildCheckItem('Eisenhower Matrix view'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: Pro Plan (POPULAR Ribbon)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1F2B) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF0D5CE5),
                      width: 2,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: const Color(0xFF0D5CE5).withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pro Plan',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
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
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (discountPercent > 0) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${finalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D5CE5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${basePrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const Text(
                              '/month',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$discountPercent% Referral Discount Applied (Next cycle)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ] else ...[
                        RichText(
                          text: TextSpan(
                            text: '₹${basePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D5CE5),
                            ),
                            children: const [
                              TextSpan(
                                text: '/month',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      _buildCheckItem('Everything Unlimited'),
                      _buildCheckItem('Infinite Habit Tracking'),
                      _buildCheckItem('Custom Focus Timers & Themes'),
                      _buildCheckItem('Advanced Insights & Trends'),
                      _buildCheckItem('Ad-Free Productivity Mode'),
                      _buildCheckItem('Priority Support'),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPremium ? const Color(0xFF10B981) : const Color(0xFF0D5CE5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: (isPremium || _isProcessing)
                              ? null
                              : () async {
                                  setState(() => _isProcessing = true);
                                  await provider.checkoutSubscription('PREMIUM', basePrice);
                                  setState(() => _isProcessing = false);

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          discountPercent > 0
                                              ? 'Upgraded to Premium with $discountPercent% referral discount (₹${finalPrice.toStringAsFixed(2)})!'
                                              : 'Upgraded to Premium successfully!',
                                        ),
                                        backgroundColor: const Color(0xFF0D5CE5),
                                      ),
                                    );
                                  }
                                },
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isPremium ? 'Currently Subscribed' : 'Upgrade Now',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D5CE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF0D5CE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
