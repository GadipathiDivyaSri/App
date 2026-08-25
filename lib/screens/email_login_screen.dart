import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/auth_api_service.dart';
import '../services/msg91_service.dart';
import '../theme/app_theme.dart';
import 'terms_conditions_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  bool _agreeToTerms = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await Msg91Service.sendEmailOtp(email);
      if (res['success'] == true) {
        setState(() => _otpSent = true);
        _showSuccess(res['message'] ?? 'OTP code sent to your email.');
      } else {
        _showError(res['message'] ?? 'Failed to send verification code.');
      }
    } catch (_) {
      _showError('Unable to connect to MSG91 service. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyAndLogin() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }

    if (otp.isEmpty) {
      _showError('Please enter the verification code.');
      return;
    }

    if (!_agreeToTerms) {
      _showError('Please accept the Terms & Conditions to proceed.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Client-side MSG91 OTP verification to obtain accessToken
      final msg91Res = await Msg91Service.verifyOtp(email: email, otp: otp);

      if (msg91Res['success'] != true || msg91Res['accessToken'] == null) {
        _showError(msg91Res['message'] ??
            'Incorrect or expired OTP. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      final String accessToken = msg91Res['accessToken'];

      // 2. Server-side validation with WrindhaOS Backend & Supabase persistence
      final authRes = await AuthApiService.verifyMsg91AccessToken(
        accessToken,
        referralCode: _referralCtrl.text.trim(),
      );

      if (authRes['success'] == true && authRes['token'] != null) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.setAuthenticatedSession(
          userMap: authRes['user'] ?? {},
          token: authRes['token'],
        );
        _showSuccess('Welcome to Wrindha OS! 🚀');
      } else {
        _showError(authRes['message'] ?? 'Authentication failed. Please retry.');
      }
    } catch (_) {
      _showError('Unable to connect to WrindhaOS. Check your internet connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Branding
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WRINDHA OS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Student Productivity Engine',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Header title
                  Text(
                    _otpSent ? 'Enter Verification Code' : 'Sign in with Email',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _otpSent
                        ? 'We sent a verification code to ${_emailCtrl.text.trim()}'
                        : 'Secure OTP authentication powered by MSG91',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Email Input Field
                  Text(
                    'Email Address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_otpSent && !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'student@domain.com',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      suffixIcon: _otpSent
                          ? IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () =>
                                  setState(() => _otpSent = false),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // OTP Input Field (if OTP dispatched)
                  if (_otpSent) ...[
                    Text(
                      'Verification Code',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: 'Enter 4 or 6-digit code',
                        counterText: '',
                        prefixIcon:
                            const Icon(Icons.shield_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Referral Code (Optional)
                    Text(
                      'Referral Code (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _referralCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'WRINDHA...',
                        prefixIcon:
                            const Icon(Icons.card_giftcard_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Terms & Conditions Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        activeColor: primaryColor,
                        onChanged: (val) =>
                            setState(() => _agreeToTerms = val ?? true),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsConditionsScreen(
                                    isReviewMode: true),
                              ),
                            );
                          },
                          child: Text.rich(
                            TextSpan(
                              text: 'I accept the ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_otpSent
                              ? _handleVerifyAndLogin
                              : _handleSendOtp),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _otpSent ? 'Verify & Continue' : 'Send OTP Code',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  // Resend Code Link
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleSendOtp,
                        child: Text(
                          'Didn\'t receive code? Resend OTP',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
