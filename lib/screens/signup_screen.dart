import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'email_otp_screen.dart';
import 'terms_conditions_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _referralCodeCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Real-time username validation
  bool? _isUsernameAvailable;
  bool _isCheckingUsername = false;
  String? _usernameFeedback;

  // Real-time referral validation
  bool? _isReferralValid;
  bool _isCheckingReferral = false;
  String? _referralFeedback;

  Timer? _debounceTimer;
  Timer? _referralDebounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _referralDebounceTimer?.cancel();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _referralCodeCtrl.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();
    final clean = value.trim().toLowerCase();

    if (clean.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameFeedback = null;
        _isCheckingUsername = false;
      });
      return;
    }

    if (clean.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameFeedback = 'Username must be at least 3 characters.';
        _isCheckingUsername = false;
      });
      return;
    }

    if (clean.length > 20) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameFeedback = 'Username cannot exceed 20 characters.';
        _isCheckingUsername = false;
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(clean)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameFeedback = 'Only letters, numbers, and underscores allowed.';
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameFeedback = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final res = await ApiService.checkUsername(clean);
      if (!mounted) return;
      setState(() {
        _isCheckingUsername = false;
        if (res['available'] == true) {
          _isUsernameAvailable = true;
          _usernameFeedback = '✓ Username is available';
        } else {
          _isUsernameAvailable = false;
          _usernameFeedback = res['error'] ?? 'Username is already taken.';
        }
      });
    });
  }

  void _onReferralChanged(String value) {
    _referralDebounceTimer?.cancel();
    final clean = value.trim().toUpperCase();

    if (clean.isEmpty) {
      setState(() {
        _isReferralValid = null;
        _referralFeedback = null;
        _isCheckingReferral = false;
      });
      return;
    }

    setState(() {
      _isCheckingReferral = true;
      _referralFeedback = null;
    });

    _referralDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final res = await ApiService.validateReferralCode(clean);
      if (!mounted) return;
      setState(() {
        _isCheckingReferral = false;
        if (res['valid'] == true) {
          _isReferralValid = true;
          final refName = res['referrerName'] ?? 'Friend';
          _referralFeedback = '✓ Valid code from $refName! 10% discount on next billing.';
        } else {
          _isReferralValid = false;
          _referralFeedback = res['message'] ?? 'Invalid referral code.';
        }
      });
    });
  }

  Future<void> _handleSignUp() async {
    final username = _usernameCtrl.text.trim().toLowerCase();
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;
    final referralCode = _referralCodeCtrl.text.trim().toUpperCase();

    // Validation checks
    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields.');
      return;
    }

    if (username.length < 3 || username.length > 20 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() => _errorMessage = 'Username must be 3-20 characters with letters, numbers, or _ only.');
      return;
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters long.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.registerInitiate(
      username: username,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      referralCode: referralCode.isNotEmpty ? referralCode : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(
            email: email,
            username: username,
            isForgotPassword: false,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Failed to initiate registration.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join WrindhaOS and start mastering your productivity.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Error Message Box
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 1. Username Field
                _buildFieldLabel('Username', isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameCtrl,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  onChanged: _onUsernameChanged,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: 'Choose a unique username',
                    prefixIcon: Icons.alternate_email_rounded,
                    isDark: isDark,
                    suffixIcon: _isCheckingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_isUsernameAvailable != null
                            ? Icon(
                                _isUsernameAvailable!
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: _isUsernameAvailable!
                                    ? const Color(0xFF10B981)
                                    : Colors.redAccent,
                                size: 20,
                              )
                            : null),
                  ),
                ),
                if (_usernameFeedback != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _usernameFeedback!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isUsernameAvailable == true
                          ? const Color(0xFF10B981)
                          : Colors.redAccent,
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // 2. Email Address Field
                _buildFieldLabel('Email Address', isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: 'Enter your email address',
                    prefixIcon: Icons.mail_outline_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Password Field
                _buildFieldLabel('Password', isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: 'Create a secure password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isDark: isDark,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: isDark ? Colors.white54 : Colors.black45,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Confirm Password Field
                _buildFieldLabel('Confirm Password', isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: Icons.lock_reset_rounded,
                    isDark: isDark,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: isDark ? Colors.white54 : Colors.black45,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Referral Code Field (Optional)
                _buildFieldLabel('Referral Code (Optional)', isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _referralCodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onChanged: _onReferralChanged,
                  onFieldSubmitted: (_) => _handleSignUp(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: 'Enter a friend\'s referral code',
                    prefixIcon: Icons.card_giftcard_rounded,
                    isDark: isDark,
                    suffixIcon: _isCheckingReferral
                        ? const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_isReferralValid != null
                            ? Icon(
                                _isReferralValid!
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: _isReferralValid!
                                    ? const Color(0xFF10B981)
                                    : Colors.redAccent,
                                size: 20,
                              )
                            : null),
                  ),
                ),
                if (_referralFeedback != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _referralFeedback!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isReferralValid == true
                          ? const Color(0xFF10B981)
                          : Colors.redAccent,
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Primary Button: Continue
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleSignUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // Legal Disclaimer
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                    );
                  },
                  child: Text(
                    'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Already have an account? Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF374151),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14.5,
        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E2235) : const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? Colors.white54 : const Color(0xFF6B7280),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0x262A85FF) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
          width: 1.5,
        ),
      ),
    );
  }
}
