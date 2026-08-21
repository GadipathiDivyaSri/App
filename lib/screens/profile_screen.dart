import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'pricing_screen.dart';
import 'payment_history_screen.dart';
import 'notification_settings_screen.dart';
import 'referral_screen.dart';
import 'about_us_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onNavigateToHome;

  const ProfileScreen({super.key, this.onNavigateToHome});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else if (onNavigateToHome != null) {
              onNavigateToHome!();
            }
          },
        ),
        title: Text(
          'Settings',
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
            // User Name & Info (No Profile Picture)
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: isDark ? AppTheme.darkIconGlow : AppTheme.primaryAccent,
                        ),
                        onPressed: () {
                          _showEditNameDialog(context, provider);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkIconBg : AppTheme.career,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'WrindhaOS Member',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkIconGlow : AppTheme.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stat Cards (Focus Score & Active Streak)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'FOCUS SCORE',
                    value: '${user.focusScore}',
                    valueColor: isDark ? AppTheme.darkIconGlow : AppTheme.primaryAccent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'ACTIVE STREAK',
                    value: '${user.activeStreak} Days',
                    valueColor: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Account Section
            _buildSectionHeader('ACCOUNT'),
            _buildMenuCard(
              context,
              items: [
                _MenuItemData(
                    icon: Icons.info_outline_rounded,
                    title: 'About Us',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutUsScreen(),
                        ),
                      );
                    }),
                _MenuItemData(
                    icon: Icons.card_membership_outlined,
                    title: 'Pricing',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PricingScreen(),
                        ),
                      );
                    }),
                _MenuItemData(
                    icon: Icons.history_rounded,
                    title: 'Payment History',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentHistoryScreen(),
                        ),
                      );
                    }),
              ],
            ),
            const SizedBox(height: 20),

            // Preferences Section
            _buildSectionHeader('PREFERENCES'),
            Container(
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
              child: Column(
                children: [
                  _buildListTile(
                    context,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notification Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.nightlight_round,
                            size: 22, color: Color(0xFF0D5CE5)),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Theme Change',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Light / Dark Segment Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2B3D)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => provider.toggleTheme(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: !isDark
                                        ? const Color(0xFF0D5CE5)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Light',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          !isDark ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => provider.toggleTheme(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0D5CE5)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Dark',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Support & Community Section
            _buildSectionHeader('SUPPORT & COMMUNITY'),
            _buildMenuCard(
              context,
              items: [
                _MenuItemData(
                    icon: Icons.help_outline_rounded,
                    title: 'Support & Care',
                    onTap: () => _showDialog(context, 'Support & Care',
                        'Contact support at help@productivityhub.io')),
                _MenuItemData(
                    icon: Icons.share_outlined,
                    title: 'Referral Page',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReferralScreen(),
                        ),
                      );
                    }),
              ],
            ),
            const SizedBox(height: 24),

            // Logout Button
            TextButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Delete Account Button
            TextButton.icon(
              onPressed: () => _showDeleteAccountDialog(context, provider),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444), size: 20),
              label: const Text(
                'Delete Account',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required List<_MenuItemData> items}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildListTile(
                context,
                icon: item.icon,
                title: item.title,
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                const Divider(height: 1, indent: 50),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF0D5CE5), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Color(0xFF94A3B8), size: 22),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController(text: provider.user.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User Name', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                provider.updateUserName(nameCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AppProvider>(context, listen: false).logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? All your habits, tasks, calendar events, focus scores, and settings will be permanently erased. This action cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              // Show loading feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deleting account and data...'),
                  duration: Duration(seconds: 1),
                ),
              );

              final res = await provider.deleteAccount();

              if (Navigator.canPop(context)) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res['message'] ?? 'Account deleted successfully.'),
                  backgroundColor: const Color(0xFF0D5CE5),
                ),
              );
            },
            child: const Text(
              'Delete Permanently',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItemData({required this.icon, required this.title, required this.onTap});
}
