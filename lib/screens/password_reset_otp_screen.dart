import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'create_new_password_screen.dart';

class PasswordResetOtpScreen extends StatefulWidget {
  final String email;
  const PasswordResetOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<PasswordResetOtpScreen> createState() => _PasswordResetOtpScreenState();
}

class _PasswordResetOtpScreenState extends State<PasswordResetOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  // 60-Second Resend Cooldown Timer with ValueNotifiers (prevents whole-page rebuilds while typing)
  Timer? _cooldownTimer;
  final ValueNotifier<int> _secondsRemainingNotifier = ValueNotifier<int>(60);
  final ValueNotifier<bool> _canResendNotifier = ValueNotifier<bool>(false);
  bool get _canResend => _canResendNotifier.value;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
    _otpController.addListener(_onOtpChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  void _onOtpChanged() {
    if (_errorMessage != null && mounted) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    _secondsRemainingNotifier.dispose();
    _canResendNotifier.dispose();
    super.dispose();
  }

  void _startCooldownTimer() {
    _secondsRemainingNotifier.value = 60;
    _canResendNotifier.value = false;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemainingNotifier.value > 0) {
        _secondsRemainingNotifier.value--;
      } else {
        _canResendNotifier.value = true;
        timer.cancel();
      }
    });
  }

  String _getMaskedEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name***@$domain';
    final prefix = name.substring(0, 2);
    return '$prefix***@$domain';
  }

  String _getOtpCode() {
    return _otpController.text.trim();
  }

  Future<void> _handleVerify() async {
    final otp = _getOtpCode();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the verification code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.forgotPasswordVerifyOtp(
      email: widget.email,
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true && res['resetToken'] != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CreateNewPasswordScreen(
            email: widget.email,
            resetToken: res['resetToken'],
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Invalid verification code. Please try again.';
      });
    }
  }

  Future<void> _handleResend() async {
    if (!_canResendNotifier.value || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final res = await ApiService.forgotPasswordInitiate(widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (res['success'] == true) {
      _otpController.clear();
      _otpFocusNode.requestFocus();
      _startCooldownTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'A verification code has been sent to your email!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Failed to resend code. Please try again.';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Title
              Text(
                'Verify your identity',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: "Enter the 6-digit verification code sent to \n"),
                    TextSpan(
                      text: _getMaskedEmail(widget.email),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Error Banner
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
                const SizedBox(height: 24),
              ],

              // 6-Digit OTP Input (Single persistent InputConnection - zero keyboard flickering)
              GestureDetector(
                onTap: () => _otpFocusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Invisible native TextField keeping single soft keyboard session alive without reconnecting
                    Opacity(
                      opacity: 0.0,
                      child: SizedBox(
                        height: 56,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          enableInteractiveSelection: false,
                          showCursor: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: (val) {
                            if (_errorMessage != null && mounted) {
                              setState(() => _errorMessage = null);
                            }
                            if (val.length == 6 && !_isLoading) {
                              _handleVerify();
                            }
                          },
                        ),
                      ),
                    ),

                    // Visual 6-Digit PIN Boxes
                    IgnorePointer(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_otpController, _otpFocusNode]),
                        builder: (context, _) {
                          final currentText = _otpController.text;
                          final hasFocus = _otpFocusNode.hasFocus;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              final isFilled = index < currentText.length;
                              final char = isFilled ? currentText[index] : '';
                              final isCurrent = hasFocus &&
                                  (index == currentText.length || (index == 5 && currentText.length == 6));

                              return Container(
                                width: 46,
                                height: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E2235) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrent
                                        ? primaryColor
                                        : (isFilled
                                            ? (isDark ? const Color(0x662A85FF) : const Color(0xFFCBD5E1))
                                            : (isDark ? const Color(0x262A85FF) : const Color(0xFFE5E7EB))),
                                    width: isCurrent ? 2.0 : 1.5,
                                  ),
                                ),
                                child: Text(
                                  char,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Verify Code Button
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
                  onPressed: _isLoading ? null : _handleVerify,
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
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Resend Code Action (Isolated from page rebuilds)
              Center(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _canResendNotifier,
                  builder: (context, canResend, _) {
                    if (canResend) {
                      return GestureDetector(
                        onTap: _isResending ? null : _handleResend,
                        child: Text(
                          _isResending ? 'Resending...' : 'Resend Code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      );
                    }
                    return ValueListenableBuilder<int>(
                      valueListenable: _secondsRemainingNotifier,
                      builder: (context, secondsRemaining, _) {
                        return Text(
                          'Resend code in ${secondsRemaining}s',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
