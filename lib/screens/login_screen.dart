import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mobile OTP controllers
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;

  // Email controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _agreeToTerms = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleMobileLogin() async {
    if (!_otpSent) {
      if (_phoneCtrl.text.trim().length >= 10) {
        final res = await ApiService.send2FAOTP(_phoneCtrl.text.trim());
        setState(() {
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? '2FA OTP sent successfully! (Use code: 1234)'),
            backgroundColor: AppTheme.primaryAccent,
          ),
        );
      }
    } else {
      final res = await ApiService.verify2FAOTP(
          _phoneCtrl.text.trim(), _otpCtrl.text.trim());
      if (res['success'] == true || _otpCtrl.text.trim() == '1234') {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.login('Alex Johnson', _phoneCtrl.text.trim());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Invalid 2FA OTP code. Please enter 1234'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleEmailLogin() {
    if (_emailCtrl.text.trim().isNotEmpty &&
        _passwordCtrl.text.trim().isNotEmpty) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.login('Alex Johnson', _emailCtrl.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
    }
  }

  void _handleGoogleLogin() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.login('Alex Johnson', 'alex.google@gmail.com');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Logo & App Name Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'WrindhaOS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to access your goals, habits & study schedule.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Segmented Tab Selector (Mobile OTP / Email ID)
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1F2B) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Mobile OTP'),
                    Tab(text: 'Email & Password'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab Views
              SizedBox(
                height: 280,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Mobile OTP View
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MOBILE NUMBER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: Icon(Icons.phone_iphone_rounded,
                                size: 20, color: primaryColor),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E1F2B)
                                : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_otpSent) ...[
                          const Text(
                            'ENTER OTP CODE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              hintText: 'Enter 4-digit OTP',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF94A3B8),
                              ),
                              counterText: '',
                              prefixIcon: Icon(
                                  Icons.lock_clock_outlined,
                                  size: 20,
                                  color: primaryColor),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E1F2B)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _handleMobileLogin,
                            child: Text(
                              _otpSent ? 'Verify & Log In' : 'Send OTP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _agreeToTerms,
                                onChanged: (val) {
                                  setState(() {
                                    _agreeToTerms = val ?? false;
                                  });
                                },
                                activeColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showTermsDialog(context),
                              child: Text(
                                'I agree to the Terms & Conditions',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Email & Password View
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EMAIL ADDRESS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: '',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: Icon(Icons.email_outlined,
                                size: 20, color: primaryColor),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E1F2B)
                                : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: Icon(Icons.lock_outline_rounded,
                                size: 20, color: primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E1F2B)
                                : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) => setState(
                                        () => _rememberMe = val ?? true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _handleEmailLogin,
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Divider
              Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFE2E8F0))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Expanded(
                      child: Divider(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFE2E8F0))),
                ],
              ),
              const SizedBox(height: 20),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  onPressed: _handleGoogleLogin,
                  icon: Icon(Icons.g_mobiledata_rounded,
                      size: 32, color: Color(0xFF4285F4)),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Link: Don't have an account? Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            '''TERMS & CONDITIONS

1. Acceptance of Terms
These Terms & Conditions ("Terms") form a binding agreement between you and WrindhaOS governing your use of the WrindhaOS mobile application and wrindhaos.in (together, the "Service"). By creating an account or using the Service, you agree to these Terms, our Privacy Policy, and our other published policies. If you do not agree, do not use the Service.

2. Eligibility
The Service is intended for students preparing for competitive examinations. If you are under 18 years of age, you may use the Service only with the consent and involvement of a parent or legal guardian, who agrees to be bound by these Terms on your behalf.

3. Your Account
• You must provide accurate information (email and/or phone number) to create an account and complete OTP verification.
• You are responsible for maintaining the confidentiality of your account credentials and for all activity under your account.
• You must notify us promptly at wrindhaos@gmail.com of any unauthorized use of your account.

4. The Service
WrindhaOS provides productivity tools including habit tracking, to-dos, an Eisenhower/priority matrix, goals and milestones, a subject/topic academic tracker, a calendar and timetable, a focus timer, a private journal, and personal expense tracking. Features available to you depend on whether you are on the Free plan or a paid Premium plan (see Section 6 and our Subscription Policy).
We may add, modify, or discontinue features at our discretion, and will provide reasonable notice for material changes that reduce Premium functionality you are actively paying for.

5. Free Tier and Usage Limits
The Free plan provides core functionality with certain usage limits (for example, a maximum number of active habits and subjects), as displayed in-app. These limits may change from time to time; current limits are always shown in the app's plan comparison screen.

6. Subscriptions and Payment
Premium plans are billed and processed entirely through Google Play Billing. We do not collect or store your payment card, UPI, or bank account details. Pricing, billing cycles, auto-renewal, and cancellation are governed by Google Play's terms in addition to our Subscription Policy and Refund & Cancellation Policy, both incorporated by reference.

7. Your Content
Content you create in the Service — journal entries, notes, goals, tasks, and similar material ("User Content") — remains yours. You grant us a limited, non-exclusive licence to store, process, and display your User Content solely to operate and provide the Service to you. See our User Content Policy for details, including how journal content is encrypted.

8. Acceptable Use
You agree to use the Service lawfully and in accordance with our Acceptable Use Policy. We may suspend or terminate accounts that violate these Terms, subject to the notice and review process described in that policy.

9. Disclaimers
WrindhaOS is a productivity and organisational tool. It is not exam-preparation content, a coaching service, or a guarantee of examination results, and it is not a medical, financial, or professional advisory service. See our full Disclaimer.

10. Limitation of Liability
To the maximum extent permitted by applicable law, [LEGAL ENTITY NAME — e.g., “GrabMyService Private Limited,” trading as WrindhaOS] shall not be liable for indirect, incidental, special, or consequential damages arising from your use of, or inability to use, the Service, including loss of data, loss of study progress, or exam outcomes. Our aggregate liability for any claim relating to the Service shall not exceed the amount you paid us, if any, in the twelve (12) months preceding the claim.

11. Termination
You may stop using the Service and request account deletion at any time (see our Account Deletion Policy). We may suspend or terminate your access for violation of these Terms, non-payment of applicable subscription fees, or as required by law.

12. Force Majeure
We will not be liable for any failure or delay in performing our obligations under these Terms where the failure or delay results from causes beyond our reasonable control, including but not limited to acts of God, natural disaster, fire, flood, war, civil unrest, labour disputes not involving our employees, government action, internet or telecommunications failures, power outages, or failures of third-party infrastructure we rely on (including Supabase or Google Play). During such an event, our obligations under these Terms will be suspended for the duration of the event, and we will make reasonable efforts to resume normal service as soon as practicable. This clause does not excuse payment obligations already due, nor does it affect refund rights you may have under our Refund & Cancellation Policy.

13. Dispute Resolution
13.1 Informal Resolution First
If a dispute arises out of or relating to these Terms or the Service, you agree to first contact us at [SUPPORT EMAIL — e.g., support@wrindhaos.in] (or, for grievances, our Grievance Officer per the Grievance Redressal Policy) and give us a reasonable opportunity — at least 30 days — to resolve the matter informally before pursuing formal proceedings.

13.2 Arbitration
If a dispute is not resolved informally within 30 days, either party may refer it to binding arbitration under the Arbitration and Conciliation Act, 1996 (as amended). The arbitration will be conducted by a sole arbitrator appointed by mutual agreement of the parties, or, failing agreement within 15 days, in accordance with the Act's default appointment procedure. The seat and venue of arbitration shall be Chittoor, Andhra Pradesh, India, India, the language of the arbitration shall be English, and the arbitrator's award shall be final and binding on both parties, subject to any right of challenge available under the Act.

13.3 Exceptions
Nothing in this Section 14 prevents either party from seeking urgent interim or injunctive relief from a court of competent jurisdiction where necessary to prevent immediate harm (for example, to stop unauthorised use of our intellectual property or ongoing misuse of the Service), or from exercising statutory rights that cannot be waived by agreement, including your right to approach a consumer forum under the Consumer Protection Act, 2019, or to raise a grievance under our Grievance Redressal Policy.

14. Governing Law and Jurisdiction
These Terms are governed by the laws of India. Subject to Section 14 (Dispute Resolution) and the Grievance Redressal Policy, courts at Chittoor, Andhra Pradesh, India shall have exclusive jurisdiction over any disputes not resolved through arbitration or that fall within the exceptions in Section 14.3.

15. Changes to These Terms
We may revise these Terms from time to time. Continued use of the Service after an update constitutes acceptance of the revised Terms. The current version is always available at wrindhaos.in/terms.

16. Contact
Questions about these Terms: wrindhaos@gmail.com''',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
