import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  final bool isReviewMode;
  final VoidCallback? onAccept;

  const TermsConditionsScreen({
    super.key,
    this.isReviewMode = false,
    this.onAccept,
  });

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
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkCardBorder : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5CE5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (onAccept != null) {
                  onAccept!();
                }
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
              label: const Text(
                'I Have Read & Accept Terms',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
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
                          color: const Color(0xFF0D5CE5).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: Color(0xFF0D5CE5),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Last Updated: August 2026',
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
                      'Applies to: WrindhaOS mobile application for Android (package: com.wrindhaos.productivity) and wrindhaos.in',
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

            _buildSection(
              isDark,
              '1',
              'Acceptance of Terms',
              'These Terms & Conditions ("Terms") form a binding agreement between you and WrindhaOS governing your use of the WrindhaOS mobile application and wrindhaos.in (together, the "Service"). By creating an account or using the Service, you agree to these Terms, our Privacy Policy, and our other published policies. If you do not agree, do not use the Service.',
            ),

            _buildSection(
              isDark,
              '2',
              'Eligibility',
              'The Service is intended for students preparing for competitive examinations. If you are under 18 years of age, you may use the Service only with the consent and involvement of a parent or legal guardian, who agrees to be bound by these Terms on your behalf.',
            ),

            _buildSection(
              isDark,
              '3',
              'Your Account',
              '• You must provide accurate information (email and/or phone number) to create an account and complete OTP verification.\n• You are responsible for maintaining the confidentiality of your account credentials and for all activity under your account.\n• You must notify us promptly at wrindhaos@gmail.com of any unauthorized use of your account.',
            ),

            _buildSection(
              isDark,
              '4',
              'The Service',
              'WrindhaOS provides productivity tools including habit tracking, to-dos, an Eisenhower/priority matrix, goals and milestones, a subject/topic academic tracker, a calendar and timetable, a focus timer, a private journal, and personal expense tracking. Features available to you depend on whether you are on the Free plan or a paid Premium plan (see Section 6 and our Subscription Policy).\n\nWe may add, modify, or discontinue features at our discretion, and will provide reasonable notice for material changes that reduce Premium functionality you are actively paying for.',
            ),

            _buildSection(
              isDark,
              '5',
              'Free Tier and Usage Limits',
              'The Free plan provides core functionality with certain usage limits (for example, a maximum number of active habits and subjects), as displayed in-app. These limits may change from time to time; current limits are always shown in the app\'s plan comparison screen.',
            ),

            _buildSection(
              isDark,
              '6',
              'Subscriptions and Payment',
              'Premium plans are billed and processed entirely through Google Play Billing. We do not collect or store your payment card, UPI, or bank account details. Pricing, billing cycles, auto-renewal, and cancellation are governed by Google Play\'s terms in addition to our Subscription Policy and Refund & Cancellation Policy, both incorporated by reference.',
            ),

            _buildSection(
              isDark,
              '7',
              'Your Content',
              'Content you create in the Service — journal entries, notes, goals, tasks, and similar material ("User Content") — remains yours. You grant us a limited, non-exclusive licence to store, process, and display your User Content solely to operate and provide the Service to you. See our User Content Policy for details, including how journal content is encrypted.',
            ),

            _buildSection(
              isDark,
              '8',
              'Acceptable Use',
              'You agree to use the Service lawfully and in accordance with our Acceptable Use Policy. We may suspend or terminate accounts that violate these Terms, subject to the notice and review process described in that policy.',
            ),

            _buildSection(
              isDark,
              '9',
              'Disclaimers',
              'WrindhaOS is a productivity and organisational tool. It is not exam-preparation content, a coaching service, or a guarantee of examination results, and it is not a medical, financial, or professional advisory service. See our full Disclaimer.',
            ),

            _buildSection(
              isDark,
              '10',
              'Limitation of Liability',
              'To the maximum extent permitted by applicable law, WrindhaOS shall not be liable for indirect, incidental, special, or consequential damages arising from your use of, or inability to use, the Service, including loss of data, loss of study progress, or exam outcomes. Our aggregate liability for any claim relating to the Service shall not exceed the amount you paid us, if any, in the twelve (12) months preceding the claim.',
            ),

            _buildSection(
              isDark,
              '11',
              'Termination',
              'You may stop using the Service and request account deletion at any time (see our Account Deletion Policy). We may suspend or terminate your access for violation of these Terms, non-payment of applicable subscription fees, or as required by law.',
            ),

            _buildSection(
              isDark,
              '12',
              'Force Majeure',
              'We will not be liable for any failure or delay in performing our obligations under these Terms where the failure or delay results from causes beyond our reasonable control, including but not limited to acts of God, natural disaster, fire, flood, war, civil unrest, labour disputes not involving our employees, government action, internet or telecommunications failures, power outages, or failures of third-party infrastructure we rely on (including Supabase or Google Play). During such an event, our obligations under these Terms will be suspended for the duration of the event, and we will make reasonable efforts to resume normal service as soon as practicable. This clause does not excuse payment obligations already due, nor does it affect refund rights you may have under our Refund & Cancellation Policy.',
            ),

            _buildSection(
              isDark,
              '13',
              'Dispute Resolution',
              '13.1 Informal Resolution First\nIf a dispute arises out of or relating to these Terms or the Service, you agree to first contact us at wrindhaos@gmail.com (or, for grievances, our Grievance Officer per the Grievance Redressal Policy) and give us a reasonable opportunity — at least 30 days — to resolve the matter informally before pursuing formal proceedings.\n\n13.2 Arbitration\nIf a dispute is not resolved informally within 30 days, either party may refer it to binding arbitration under the Arbitration and Conciliation Act, 1996 (as amended). The arbitration will be conducted by a sole arbitrator appointed by mutual agreement of the parties, or, failing agreement within 15 days, in accordance with the Act\'s default appointment procedure. The seat and venue of arbitration shall be Chittoor, Andhra Pradesh, India, the language of the arbitration shall be English, and the arbitrator\'s award shall be final and binding on both parties, subject to any right of challenge available under the Act.\n\n13.3 Exceptions\nNothing in this Section 13 prevents either party from seeking urgent interim or injunctive relief from a court of competent jurisdiction where necessary to prevent immediate harm (for example, to stop unauthorised use of our intellectual property or ongoing misuse of the Service), or from exercising statutory rights that cannot be waived by agreement, including your right to approach a consumer forum under the Consumer Protection Act, 2019, or to raise a grievance under our Grievance Redressal Policy.',
            ),

            _buildSection(
              isDark,
              '14',
              'Governing Law and Jurisdiction',
              'These Terms are governed by the laws of India. Subject to Section 13 (Dispute Resolution) and the Grievance Redressal Policy, courts at Chittoor, Andhra Pradesh, India shall have exclusive jurisdiction over any disputes not resolved through arbitration or that fall within the exceptions in Section 13.3.',
            ),

            _buildSection(
              isDark,
              '15',
              'Changes to These Terms',
              'We may revise these Terms from time to time. Continued use of the Service after an update constitutes acceptance of the revised Terms. The current version is always available at wrindhaos.in/terms.',
            ),

            _buildSection(
              isDark,
              '16',
              'Contact',
              'Questions about these Terms:\nEmail: wrindhaos@gmail.com',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(bool isDark, String number, String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131F37) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
