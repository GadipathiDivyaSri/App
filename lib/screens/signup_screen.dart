import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'terms_conditions_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _referralCodeCtrl = TextEditingController();
  bool _otpSent = false;
  bool _agreeTerms = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _referralCodeCtrl.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    final isMobileTab = _tabController.index == 0;
    final input = isMobileTab ? _phoneCtrl.text.trim() : _emailCtrl.text.trim();

    if (input.isNotEmpty) {
      setState(() {
        _otpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to $input! (Use code: 1234)'),
          backgroundColor: AppTheme.primaryAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone or email first')),
      );
    }
  }

  void _handleSignUp() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept our Terms & Conditions to create an account'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final isMobileTab = _tabController.index == 0;
    final contact = isMobileTab ? _phoneCtrl.text.trim() : _emailCtrl.text.trim();
    final refCode = _referralCodeCtrl.text.trim();

    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.signup(
      _nameCtrl.text.trim(),
      contact,
      refCode: refCode.isNotEmpty ? refCode : null,
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _handleGoogleSignUp() {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept our Terms & Conditions to sign up'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final refCode = _referralCodeCtrl.text.trim();
    provider.signup(
      'Alex Johnson',
      'alex.google@gmail.com',
      refCode: refCode.isNotEmpty ? refCode : null,
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account 🚀',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign up with your details to unlock personal growth and study dashboards.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // FULL NAME
              const Text(
                'FULL NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., Alex Johnson',
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      size: 20, color: Color(0xFF0D5CE5)),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1F2B)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Tab Selector (Mobile OTP / Email OTP)
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1F2B)
                      : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: const Color(0xFF0D5CE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Mobile OTP'),
                    Tab(text: 'Email OTP'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab View Contents
              SizedBox(
                height: _otpSent ? 160 : 80,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Mobile View
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '+91 9876543210',
                                  prefixIcon: const Icon(
                                      Icons.phone_iphone_rounded,
                                      size: 20,
                                      color: Color(0xFF0D5CE5)),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF1E1F2B)
                                      : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D5CE5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _handleSendOtp,
                              child: const Text('OTP',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              hintText: 'Enter 4-digit OTP (1234)',
                              counterText: '',
                              prefixIcon: const Icon(
                                  Icons.lock_clock_outlined,
                                  size: 20,
                                  color: Color(0xFF0D5CE5)),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E1F2B)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Email View
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'alex@example.com',
                                  prefixIcon: const Icon(Icons.email_outlined,
                                      size: 20, color: Color(0xFF0D5CE5)),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF1E1F2B)
                                      : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D5CE5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _handleSendOtp,
                              child: const Text('OTP',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              hintText: 'Enter 4-digit OTP (1234)',
                              counterText: '',
                              prefixIcon: const Icon(
                                  Icons.lock_clock_outlined,
                                  size: 20,
                                  color: Color(0xFF0D5CE5)),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E1F2B)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // PASSWORD
              const Text(
                'CREATE PASSWORD',
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
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      size: 20, color: Color(0xFF0D5CE5)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1F2B)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // REFERRAL CODE (OPTIONAL)
              const Text(
                'REFERRAL CODE (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _referralCodeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g., WRINDHA7K92',
                  prefixIcon: const Icon(Icons.discount_outlined,
                      size: 20, color: Color(0xFF0D5CE5)),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1F2B)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Terms & Conditions Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreeTerms,
                      activeColor: const Color(0xFF0D5CE5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: (val) =>
                          setState(() => _agreeTerms = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                          child: Text(
                            'By signing up, you accept our ',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsConditionsScreen(),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D5CE5),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                          child: Text(
                            ' and Privacy Policy.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Create Account Primary Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5CE5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _handleSignUp,
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Google Sign Up
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  onPressed: _handleGoogleSignUp,
                  icon: const Icon(Icons.g_mobiledata_rounded,
                      size: 32, color: Color(0xFF4285F4)),
                  label: const Text(
                    'Sign Up with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Already have an account? Log In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D5CE5),
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
}
