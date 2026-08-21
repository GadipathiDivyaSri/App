import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Us',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: isDark
                    ? Border.all(color: AppTheme.darkCardBorder, width: 1)
                    : null,
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.primaryColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WrindhaOS',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Version 1.0.0 (Production)',
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131F37) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Applies to: WrindhaOS mobile application for Android (package: com.wrindhaos.productivity) and the wrindhaos.in website',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Who We Are
            _buildSectionCard(
              context,
              isDark: isDark,
              number: '1',
              title: 'Who We Are',
              icon: Icons.groups_rounded,
              child: Text(
                'WrindhaOS is a productivity and study-management application built for students preparing for competitive examinations such as NEET, JEE, and UPSC. WrindhaOS is developed and operated by WrindhaOS ("we," "us," "our," or the "Company"), based in Chittoor, Andhra Pradesh, India.\n\nWrindhaOS was created to give exam aspirants a single workspace for the discipline that competitive preparation demands — habit tracking, subject and topic mastery tracking, a goals hierarchy, an Eisenhower-style priority matrix, a calendar and timetable, a private journal, a focus/study timer, and lightweight personal expense tracking — instead of juggling five different apps.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: What We Do
            _buildSectionCard(
              context,
              isDark: isDark,
              number: '2',
              title: 'What We Do',
              icon: Icons.checklist_rounded,
              child: Column(
                children: [
                  _buildBulletPoint(
                    isDark,
                    'Help students plan and structure daily, weekly, and long-term study schedules.',
                  ),
                  _buildBulletPoint(
                    isDark,
                    'Track habits, study sessions, and subject/topic mastery over time.',
                  ),
                  _buildBulletPoint(
                    isDark,
                    'Provide a private, encrypted journal for reflection and mental well-being check-ins.',
                  ),
                  _buildBulletPoint(
                    isDark,
                    'Offer a career roadmap and goal-hierarchy view to connect daily effort to long-term outcomes.',
                  ),
                  _buildBulletPoint(
                    isDark,
                    'Provide light personal finance tracking (expenses and monthly budgets) as a study-life management tool.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 3: Our Approach to Privacy
            _buildSectionCard(
              context,
              isDark: isDark,
              number: '3',
              title: 'Our Approach to Privacy',
              icon: Icons.security_rounded,
              child: Text(
                'WrindhaOS is built on an "owner-only" data architecture: your personal data — including your journal, habits, goals, subjects, tasks, and calendar — is protected by database-level access rules that restrict access to your own account. Our own administrators do not have standing access to read your private content; access is limited to account, subscription, and aggregate usage metadata needed to operate the service. See our Privacy Policy and Security & Data Protection Statement for details.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section 4: Contact
            _buildSectionCard(
              context,
              isDark: isDark,
              number: '4',
              title: 'Contact',
              icon: Icons.mail_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For general enquiries, please see our Contact Us page or write to:',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: SelectableText(
                            'wrindhaos@gmail.com',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required bool isDark,
    required String number,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: AppTheme.darkCardBorder, width: 1)
            : null,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131F37) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: isDark ? AppTheme.darkIconGlow : const Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
