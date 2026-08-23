import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class ChooseUsernameScreen extends StatefulWidget {
  final String email;
  final String name;
  final String googleId;
  final String suggestedUsername;
  final List<String> initialSuggestions;

  const ChooseUsernameScreen({
    super.key,
    required this.email,
    required this.name,
    required this.googleId,
    required this.suggestedUsername,
    this.initialSuggestions = const [],
  });

  @override
  State<ChooseUsernameScreen> createState() => _ChooseUsernameScreenState();
}

class _ChooseUsernameScreenState extends State<ChooseUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;

  Timer? _debounceTimer;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;
  List<String> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.suggestedUsername);
    _suggestions = List.from(widget.initialSuggestions);
    _usernameCtrl.addListener(_onUsernameChanged);
    _checkInitialUsername();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _usernameCtrl.removeListener(_onUsernameChanged);
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _checkInitialUsername() async {
    final text = _usernameCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isCheckingUsername = true);
    final res = await ApiService.checkUsernameAvailability(text);
    if (!mounted) return;
    setState(() {
      _isCheckingUsername = false;
      _isUsernameAvailable = res['available'] == true;
      _usernameError = res['available'] == true ? null : res['error'];
      if (res['suggestions'] != null) {
        _suggestions = (res['suggestions'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      }
    });
  }

  void _onUsernameChanged() {
    final text = _usernameCtrl.text.trim();
    _debounceTimer?.cancel();

    if (text.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = null;
        _suggestions = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isCheckingUsername = true);
      final res = await ApiService.checkUsernameAvailability(text);
      if (!mounted) return;
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = res['available'] == true;
        _usernameError = res['available'] == true ? null : res['error'];
        if (res['suggestions'] != null) {
          _suggestions = (res['suggestions'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        }
      });
    });
  }

  void _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isUsernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_usernameError ?? 'Please choose an available username'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final chosenUsername = _usernameCtrl.text.trim();

    setState(() => _isLoading = true);
    final res = await ApiService.googleCompleteRegistration(
      email: widget.email,
      name: widget.name,
      googleId: widget.googleId,
      username: chosenUsername,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      final user = UserProfile.fromJson(res['user']);
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loginWithUser(user, res['token']);

      // Dismiss all auth screens and land on Dashboard
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to finalize account'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primaryAccent;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Header
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.badge_outlined,
                      color: primaryColor, size: 28),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Choose Your Username',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Your username will be used to identify your WrindhaOS account.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Username Input Field
                Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. kalyan_g',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      size: 20,
                    ),
                    suffixIcon: _isCheckingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _isUsernameAvailable == true
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981), size: 20)
                            : _isUsernameAvailable == false
                                ? const Icon(Icons.cancel_rounded,
                                    color: Colors.redAccent, size: 20)
                                : null,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please choose a username';
                    }
                    final clean = val.trim();
                    if (clean.length < 3 || clean.length > 20) {
                      return 'Username must be 3–20 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(clean)) {
                      return 'Letters, numbers, and _ only (no spaces)';
                    }
                    return null;
                  },
                ),

                // Availability feedback
                if (_isUsernameAvailable == true) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.check,
                          color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '✓ ${_usernameCtrl.text.trim()} is available',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else if (_isUsernameAvailable == false) ...[
                  const SizedBox(height: 6),
                  Text(
                    _usernameError ??
                        '${_usernameCtrl.text.trim()} is already taken.',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Suggestions:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _suggestions.map((sug) {
                        return ActionChip(
                          label: Text(sug),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                          backgroundColor: primaryColor.withOpacity(0.08),
                          side: BorderSide(
                            color: primaryColor.withOpacity(0.25),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onPressed: () {
                            _usernameCtrl.text = sug;
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
                const SizedBox(height: 36),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
