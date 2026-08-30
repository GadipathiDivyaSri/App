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
import 'terms_conditions_screen.dart';

/// Unified Authentication Screen for WrindhaOS
/// 
/// Authentication Modes:
/// 1. Existing User -> Login (Username/Email + Password)
/// 2. New User -> Create Account (Full Name, Username, Email, Password, Terms + Create Account CTA)
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
  bool _rememberMe = true;

  // --- SIGNUP CONTROLLERS ---
  final _signupNameController = TextEditingController();
  final _signupUsernameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  final _signupReferralController = TextEditingController();
  bool _signupObscurePassword = true;
  bool _signupObscureConfirm = true;
  bool _agreeToTerms = true;
  bool _isCreatingAccount = false;

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
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupUsernameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _signupReferralController.dispose();
    _debounceTimer?.cancel();
    _countdownTimer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // USERNAME AVAILABILITY CHECKER
  // ---------------------------------------------------------------------------
  void _onUsernameChanged(String val) {
    final clean = val.trim();
    _debounceTimer?.cancel();

    if (clean.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameError = null;
      });
      return;
    }

    if (clean.length < 3) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameError = 'Username must be at least 3 characters.';
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
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
        _loginError = res['message'] ?? 'Invalid credentials. Please try again.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 2. CREATE ACCOUNT / SIGNUP ACTION
  // ---------------------------------------------------------------------------
  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();
    final name = _signupNameController.text.trim();
    final username = _signupUsernameController.text.trim();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text;
    final confirmPassword = _signupConfirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => _signupError = 'Please enter your Full Name.');
      return;
    }
    if (username.isEmpty) {
      setState(() => _signupError = 'Please choose a Username.');
      return;
    }
    if (_isUsernameAvailable == false) {
      setState(() => _signupError = 'Please select an available username.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _signupError = 'Please enter a valid Email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _signupError = 'Please enter a Password.');
      return;
    }
    if (password.length < 6) {
      setState(() => _signupError = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirmPassword && confirmPassword.isNotEmpty) {
      setState(() => _signupError = 'Passwords do not match.');
      return;
    }
    if (!_agreeToTerms) {
      setState(() => _signupError = 'Please accept the Terms & Conditions to proceed.');
      return;
    }

    setState(() {
      _isCreatingAccount = true;
      _signupError = null;
    });

    // Send verification OTP or complete registration
    await _handleSendOtp();
    if (mounted) {
      setState(() => _isCreatingAccount = false);
    }
  }

  Future<void> _handleSendOtp() async {
    final email = _signupEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _signupError = 'Please enter a valid Email address.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _signupError = null;
    });

    final res = await Msg91Service.sendEmailOtp(email);

    if (!mounted) return;
    setState(() => _isSendingOtp = false);

    if (res['success'] == true) {
      _reqId = res['reqId'] ?? res['req_id'];
      setState(() {
        _isOtpSent = true;
        _resendAttempts = 0;
      });
      _startResendCountdown();
    } else {
      setState(() {
        _signupError = res['message'] ?? 'Failed to send OTP. Please try again.';
      });
    }
  }

  void _startResendCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _resendCountdown = Msg91Config.resendIntervalSeconds;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 1) {
          _resendCountdown--;
        } else {
          _resendCountdown = 0;
          _canResend = _resendAttempts < Msg91Config.maxResendCount;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text.trim()).join();
    if (otp.length != 6) {
      setState(() => _signupError = 'Please enter all 6 digits of the OTP.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _signupError = null;
    });

    final email = _signupEmailController.text.trim();
    final username = _signupUsernameController.text.trim();
    final name = _signupNameController.text.trim();
    final password = _signupPasswordController.text;

    final verifyRes = await Msg91Service.verifyEmailOtp(
      email: email,
      otp: otp,
      reqId: _reqId,
    );

    if (!mounted) return;

    if (verifyRes['success'] == true) {
      final user = UserProfile(
        id: 'u_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        name: name.isNotEmpty ? name : username,
        contact: email,
        focusScore: 95,
        activeStreak: 1,
        isPremium: false,
        token: verifyRes['token'],
      );

      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loginWithUser(user, verifyRes['token']);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _isVerifyingOtp = false;
        _signupError = verifyRes['message'] ?? 'Invalid OTP. Please check the code sent to your email.';
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend || _isResending) return;
    if (_resendAttempts >= Msg91Config.maxResendCount) {
      setState(() => _signupError = 'Resend limit reached (2 attempts). Please try again later.');
      return;
    }

    setState(() {
      _isResending = true;
      _signupError = null;
    });

    final email = _signupEmailController.text.trim();
    final res = await Msg91Service.retryEmailOtp(email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (res['success'] == true) {
      _resendAttempts++;
      _startResendCountdown();
    } else {
      setState(() {
        _signupError = res['message'] ?? 'Failed to resend OTP.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : const Color(0xFFE05638);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFFFF9F0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. BRAND BADGE WITH OFFICIAL WRINDHA 'W' LOGO
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D5CE5).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/wrindha_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF0D5CE5),
                              alignment: Alignment.center,
                              child: const Text('W', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'WrindhaOS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. SEGMENTED TAB SWITCHER [ Login ] [ Create Account ]
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

                  // 3. MAIN FORM CONTAINER
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
                    child: _isSignUp
                        ? _buildSignUpForm(isDark, textPrimary, textSecondary, primaryColor)
                        : _buildLoginForm(isDark, textPrimary, textSecondary, primaryColor),
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
          'Welcome Back',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to access your goals, habits & study schedule.',
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
        const SizedBox(height: 20),

        // Username
        Text('USERNAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _loginIdentifierController,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter username or email',
            prefixIcon: Icon(Icons.person_outline_rounded, color: primaryColor, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // Password
        Text('PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _loginPasswordController,
          obscureText: _loginObscurePassword,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_loginObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: textSecondary),
              onPressed: () => setState(() => _loginObscurePassword = !_loginObscurePassword),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),

        // Remember me & Forgot Password
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
                    onChanged: (val) => setState(() => _rememberMe = val ?? true),
                  ),
                ),
                const SizedBox(width: 6),
                Text('Remember me', style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please contact support or sign in with your verified email.')),
                );
              },
              child: Text('Forgot Password?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor)),
            ),
          ],
        ),

        // Error message
        if (_loginError != null) ...[
          const SizedBox(height: 14),
          _buildErrorBanner(_loginError!, isDark),
        ],

        const SizedBox(height: 24),

        // Login Action Button
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
                : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 16),

        // Switch to Sign Up
        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _isSignUp = true;
              _loginError = null;
              _signupError = null;
            }),
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: textSecondary, fontSize: 13.5),
                children: [
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
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
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => _isSignUp = false),
            ),
            const SizedBox(width: 8),
            Text(
              'Create Account',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Sign up with your details to unlock personal growth and study dashboards.',
          style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),

        // 1. FULL NAME
        Text('FULL NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _signupNameController,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'e.g. Alex Johnson',
            prefixIcon: Icon(Icons.person_outline_rounded, color: primaryColor, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // 2. USERNAME with availability indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('USERNAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: textSecondary)),
            if (_isCheckingUsername)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
            else if (_isUsernameAvailable == true)
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text('Available ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              )
            else if (_isUsernameAvailable == false)
              Row(
                children: [
                  const Icon(Icons.cancel_rounded, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(_usernameError ?? 'Unavailable', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _signupUsernameController,
          onChanged: _onUsernameChanged,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Choose your unique username',
            prefixIcon: Icon(Icons.alternate_email_rounded, color: primaryColor, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // 3. EMAIL ADDRESS
        Text('EMAIL ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.mail_outline_rounded, color: primaryColor, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // 4. CREATE PASSWORD
        Text('CREATE PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _signupPasswordController,
          obscureText: _signupObscurePassword,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'At least 6 characters',
            prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_signupObscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: textSecondary),
              onPressed: () => setState(() => _signupObscurePassword = !_signupObscurePassword),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // 5. REFERRAL CODE (OPTIONAL)
        Text('REFERRAL CODE (OPTIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _signupReferralController,
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Have a referral code? Enter it here',
            prefixIcon: Icon(Icons.loyalty_outlined, color: primaryColor, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF242321) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // 6. Terms & Conditions Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
                      SizedBox(width: 8),
                      Text('Terms & Conditions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('ACCEPTED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '16 binding sections for exam aspirants & users.',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '✓ Terms Read & Accepted (Tap to Re-read)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Checkbox confirmation
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _agreeToTerms,
                activeColor: primaryColor,
                onChanged: (val) => setState(() => _agreeToTerms = val ?? true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'I confirm that I have read and agree to the Terms & Conditions and Privacy Policy.',
                style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.3),
              ),
            ),
          ],
        ),

        // Error banner
        if (_signupError != null) ...[
          const SizedBox(height: 14),
          _buildErrorBanner(_signupError!, isDark),
        ],

        const SizedBox(height: 24),

        // 7. PROMINENT CREATE ACCOUNT BUTTON
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isCreatingAccount || _isSendingOtp ? null : _handleCreateAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isCreatingAccount || _isSendingOtp
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 16),

        // Switch to Login
        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              _isSignUp = false;
              _loginError = null;
              _signupError = null;
            }),
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(color: textSecondary, fontSize: 13.5),
                children: [
                  TextSpan(
                    text: 'Log In',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
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
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => _isOtpSent = false),
            ),
            const SizedBox(width: 8),
            Text(
              'Verify Email OTP',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit verification code sent to:\n${_signupEmailController.text.trim()}',
          style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 24),

        // 6-digit OTP fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF242321) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (val.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // Resend Timer & Button
        Center(
          child: _resendCountdown > 0
              ? Text(
                  'Resend OTP in $_resendCountdown seconds',
                  style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                )
              : TextButton(
                  onPressed: _canResend ? _handleResendOtp : null,
                  child: Text(
                    _resendAttempts >= Msg91Config.maxResendCount
                        ? 'Resend limit reached'
                        : (_isResending ? 'Resending...' : 'Resend OTP'),
                    style: TextStyle(
                      color: _canResend ? primaryColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
        ),

        if (_signupError != null) ...[
          const SizedBox(height: 14),
          _buildErrorBanner(_signupError!, isDark),
        ],

        const SizedBox(height: 24),

        // Verify Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isVerifyingOtp ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isVerifyingOtp
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Verify & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
