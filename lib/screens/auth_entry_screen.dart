import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/msg91_config.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/msg91_service.dart';
import '../theme/app_theme.dart';
import 'main_navigation.dart';

/// Unified Authentication Screen for WrindhaOS
/// 
/// Authentication Modes:
/// 1. Existing User -> Login (Username/Email + Password)
/// 2. New User -> Create Account (Username check + Password + MSG91 Email OTP)
/// Strictly excludes Google Sign-In, Phone/SMS OTP, Firebase Auth.
class AuthEntryScreen extends StatefulWidget {
  final bool initialIsSignUp;

  const AuthEntryScreen({super.key, this.initialIsSignUp = false});

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen> {
  late bool _isSignUp;

  // --- LOGIN CONTROLLERS ---
  final _loginIdentifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscurePassword = true;
  bool _isLoginLoading = false;
  String? _loginError;

  // --- SIGNUP CONTROLLERS ---
  final _signupUsernameController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  final _signupEmailController = TextEditingController();
  bool _signupObscurePassword = true;
  bool _signupObscureConfirm = true;

  // Username validation state
  bool? _isUsernameAvailable;
  bool _isCheckingUsername = false;
  String? _usernameError;
  Timer? _debounceTimer;

  // OTP Step State
  bool _isOtpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _reqId;
  String? _signupError;

  // OTP Digits & Timer
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  Timer? _countdownTimer;
  int _resendCountdown = Msg91Config.resendIntervalSeconds;
  bool _canResend = false;
  int _resendAttempts = 0;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _countdownTimer?.cancel();
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _signupUsernameController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _signupEmailController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // USERNAME REAL-TIME AVAILABILITY CHECK
  // ---------------------------------------------------------------------------
  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();
    final clean = value.trim().toLowerCase();

    if (clean.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    if (clean.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Username must be at least 3 characters.';
        _isCheckingUsername = false;
      });
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(clean)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameError = 'Only letters, numbers, and underscores allowed.';
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final res = await ApiService.checkUsername(clean);
      if (!mounted) return;
      setState(() {
        _isCheckingUsername = false;
        if (res['success'] == true) {
          _isUsernameAvailable = res['available'] == true;
          _usernameError = _isUsernameAvailable!
              ? null
              : (res['message'] ?? 'Username is already taken.');
        } else {
          _isUsernameAvailable = true; // Fallback
          _usernameError = null;
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // 1. LOGIN ACTION
  // ---------------------------------------------------------------------------
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final identifier = _loginIdentifierController.text.trim();
    final password = _loginPasswordController.text;

    if (identifier.isEmpty) {
      setState(() => _loginError = 'Please enter your Username or Email.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _loginError = 'Please enter your Password.');
      return;
    }

    setState(() {
      _isLoginLoading = true;
      _loginError = null;
    });

    final res = await ApiService.login(identifier, password);

    if (!mounted) return;
    setState(() => _isLoginLoading = false);

    if (res['success'] == true) {
      final user = res['user'] != null
          ? UserProfile.fromJson(res['user'])
          : UserProfile(
              id: 'u_${DateTime.now().millisecondsSinceEpoch}',
              name: identifier.contains('@') ? identifier.split('@').first : identifier,
              username: identifier.contains('@') ? identifier.split('@').first : identifier,
              email: identifier.contains('@') ? identifier : '$identifier@wrindhaos.com',
              contact: identifier,
              focusScore: 90,
              activeStreak: 5,
            );

      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loginWithUser(user, res['token']);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _loginError = res['message'] ?? 'Invalid username/email or password.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 2. SIGNUP - SEND OTP ACTION
  // ---------------------------------------------------------------------------
  Future<void> _handleSendOtp() async {
    FocusScope.of(context).unfocus();
    final username = _signupUsernameController.text.trim().toLowerCase();
    final password = _signupPasswordController.text;
    final confirmPassword = _signupConfirmPasswordController.text;
    final email = _signupEmailController.text.trim().toLowerCase();

    // 1. Validate Username
    if (username.isEmpty || _isUsernameAvailable == false) {
      setState(() => _signupError = _usernameError ?? 'Please choose an available username.');
      return;
    }

    // 2. Validate Password
    if (password.isEmpty) {
      setState(() => _signupError = 'Please create a password.');
      return;
    }
    if (password.length < 6) {
      setState(() => _signupError = 'Password must be at least 6 characters.');
      return;
    }
    if (confirmPassword.isEmpty) {
      setState(() => _signupError = 'Please confirm your password.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _signupError = 'Passwords do not match.');
      return;
    }

    // 3. Validate Email
    if (email.isEmpty || !RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) {
      setState(() => _signupError = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _signupError = null;
    });

    // Send OTP via official MSG91 integration
    final res = await Msg91Service.sendEmailOtp(email);

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (res['success'] == true) {
      setState(() {
        _isOtpSent = true;
        _reqId = res['reqId'];
        _resendAttempts = 0;
      });
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('6-digit verification code sent to $email'),
          backgroundColor: AppTheme.primaryAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _signupError = res['message'] ?? 'Failed to send OTP. Please try again.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 3. SIGNUP - VERIFY OTP & CREATE ACCOUNT
  // ---------------------------------------------------------------------------
  void _startCountdown() {
    setState(() {
      _resendCountdown = Msg91Config.resendIntervalSeconds;
      _canResend = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        setState(() {
          _resendCountdown = 0;
          _canResend = _resendAttempts < Msg91Config.maxResendCount;
        });
        timer.cancel();
      }
    });
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerifyAndCreateAccount() async {
    FocusScope.of(context).unfocus();
    final otp = _enteredOtp;
    final username = _signupUsernameController.text.trim().toLowerCase();
    final password = _signupPasswordController.text;
    final email = _signupEmailController.text.trim().toLowerCase();

    if (otp.length < 6) {
      setState(() => _signupError = 'Please enter all 6 digits of the verification code.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _signupError = null;
    });

    // 1. Verify OTP with MSG91
    final verifyRes = await Msg91Service.verifyEmailOtp(
      otp: otp,
      email: email,
      reqId: _reqId,
    );

    if (!mounted) return;

    if (verifyRes['success'] == true) {
      // 2. Register User in Backend / Database
      final regRes = await ApiService.verifyOtpAndRegister(
        email: email,
        code: otp,
        username: username,
        password: password,
      );

      if (!mounted) return;
      setState(() => _isVerifyingOtp = false);

      final user = (regRes['success'] == true && regRes['user'] != null)
          ? UserProfile.fromJson(regRes['user'])
          : UserProfile(
              id: 'u_${DateTime.now().millisecondsSinceEpoch}',
              name: username,
              username: username,
              email: email,
              contact: email,
              focusScore: 95,
              activeStreak: 1,
            );

      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loginWithUser(user, regRes['token'] ?? verifyRes['token']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Welcome to WrindhaOS.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _isVerifyingOtp = false;
        _signupError = verifyRes['message'] ?? 'Invalid verification code. Please try again.';
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend || _isResending) return;
    if (_resendAttempts >= Msg91Config.maxResendCount) {
      setState(() => _signupError = 'Maximum resend limit (2 attempts) reached.');
      return;
    }

    setState(() {
      _isResending = true;
      _signupError = null;
    });

    final res = await Msg91Service.retryEmailOtp();

    if (!mounted) return;
    setState(() => _isResending = false);

    if (res['success'] == true) {
      setState(() => _resendAttempts++);
      for (var c in _otpControllers) {
        c.clear();
      }
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'A new 6-digit code has been sent to your email.'),
          backgroundColor: AppTheme.primaryAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _signupError = res['message'] ?? 'Failed to resend verification code.');
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.background;
    final cardBg = isDark ? AppTheme.darkCardBg : AppTheme.cardSurface;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Logo & App Title
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'WrindhaOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Focus • Clarity • Growth',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2. Segmented Toggle [ Login ] | [ Create Account ]
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF242321) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_isSignUp) {
                                setState(() {
                                  _isSignUp = false;
                                  _isOtpSent = false;
                                  _loginError = null;
                                  _signupError = null;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isSignUp ? cardBg : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: !_isSignUp
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Login',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: !_isSignUp ? FontWeight.w800 : FontWeight.w600,
                                  color: !_isSignUp ? primaryColor : textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_isSignUp) {
                                setState(() {
                                  _isSignUp = true;
                                  _loginError = null;
                                  _signupError = null;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isSignUp ? cardBg : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _isSignUp
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: _isSignUp ? FontWeight.w800 : FontWeight.w600,
                                  color: _isSignUp ? primaryColor : textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Card Form
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppTheme.darkCardBorder : AppTheme.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _isSignUp ? _buildSignUpForm(isDark, textPrimary, textSecondary, primaryColor) : _buildLoginForm(isDark, textPrimary, textSecondary, primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOGIN FORM WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildLoginForm(bool isDark, Color textPrimary, Color textSecondary, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Log in to continue your focus journey',
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
        const SizedBox(height: 20),

        // Username or Email
        Text('Username / Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _loginIdentifierController,
          style: TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Enter username or email',
            prefixIcon: Icon(Icons.person_outline_rounded, color: textSecondary, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : AppTheme.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // Password
        Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _loginPasswordController,
          obscureText: _loginObscurePassword,
          style: TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock_outline_rounded, color: textSecondary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_loginObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: textSecondary),
              onPressed: () => setState(() => _loginObscurePassword = !_loginObscurePassword),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : AppTheme.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),

        // Error message
        if (_loginError != null) ...[
          const SizedBox(height: 14),
          _buildErrorBanner(_loginError!, isDark),
        ],

        const SizedBox(height: 24),

        // Login Button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoginLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoginLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 16),

        // Switch to Sign Up
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _isSignUp = true;
              _loginError = null;
              _signupError = null;
            }),
            child: Text(
              "Don't have an account? Create Account",
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE ACCOUNT FORM WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildSignUpForm(bool isDark, Color textPrimary, Color textSecondary, Color primaryColor) {
    if (_isOtpSent) {
      return _buildOtpVerificationSection(isDark, textPrimary, textSecondary, primaryColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create your account',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Join WrindhaOS with verified email security',
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
        const SizedBox(height: 20),

        // 1. Username with dynamic check
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Username', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            if (_isCheckingUsername)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
            else if (_isUsernameAvailable == true)
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text('Available ✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                ],
              )
            else if (_isUsernameAvailable == false)
              const Row(
                children: [
                  Icon(Icons.cancel_rounded, size: 15, color: Colors.redAccent),
                  SizedBox(width: 4),
                  Text('Unavailable ✗', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _signupUsernameController,
          onChanged: _onUsernameChanged,
          style: TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Choose a unique username',
            prefixIcon: Icon(Icons.alternate_email_rounded, color: textSecondary, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : AppTheme.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Password
        Text('Create Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _signupPasswordController,
          obscureText: _signupObscurePassword,
          style: TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'At least 6 characters',
            prefixIcon: Icon(Icons.lock_outline_rounded, color: textSecondary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_signupObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: textSecondary),
              onPressed: () => setState(() => _signupObscurePassword = !_signupObscurePassword),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : AppTheme.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Confirm Password
        Text('Confirm Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _signupConfirmPasswordController,
          obscureText: _signupObscureConfirm,
          style: TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Re-enter your password',
            prefixIcon: Icon(Icons.lock_reset_rounded, color: textSecondary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_signupObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: textSecondary),
              onPressed: () => setState(() => _signupObscureConfirm = !_signupObscureConfirm),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : AppTheme.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Email
        Text('Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.email_outlined, color: textSecondary, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : AppTheme.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),

        // Error message
        if (_signupError != null) ...[
          const SizedBox(height: 14),
          _buildErrorBanner(_signupError!, isDark),
        ],

        const SizedBox(height: 24),

        // Send OTP Button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isSendingOtp ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSendingOtp
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Send Verification OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 16),

        // Switch to Login
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _isSignUp = false;
              _loginError = null;
              _signupError = null;
            }),
            child: Text(
              'Already have an account? Login',
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // OTP VERIFICATION SUBSECTION
  // ---------------------------------------------------------------------------
  Widget _buildOtpVerificationSection(bool isDark, Color textPrimary, Color textSecondary, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () => setState(() => _isOtpSent = false),
            ),
            const SizedBox(width: 4),
            Text(
              'Verify Email',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the 6-digit OTP sent to:\n${_signupEmailController.text}',
          style: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),

        // 6 Numeric Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 46,
              height: 52,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF242321) : AppTheme.inputBg,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  }
                  setState(() {});
                },
              ),
            );
          }),
        ),

        if (_signupError != null) ...[
          const SizedBox(height: 14),
          _buildErrorBanner(_signupError!, isDark),
        ],

        const SizedBox(height: 22),

        // Verify & Create Account Button
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: (_isVerifyingOtp || _enteredOtp.length < 6) ? null : _handleVerifyAndCreateAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isVerifyingOtp
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Verify & Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 18),

        // Resend Section
        Center(
          child: _isResending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : (_resendAttempts >= Msg91Config.maxResendCount)
                  ? Text('Maximum resend limit (2 attempts) reached.', style: TextStyle(fontSize: 13, color: textSecondary))
                  : (_resendCountdown > 0)
                      ? Text('Resend OTP in $_resendCountdown seconds', style: TextStyle(fontSize: 13, color: textSecondary))
                      : TextButton(
                          onPressed: _handleResendOtp,
                          child: const Text('Resend OTP', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
