import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static String baseUrl = 'http://localhost:3000/api';

  static const String _tokenKey = 'wrindha_auth_token';
  static const String _userKey = 'wrindha_auth_user';

  // ---------------------------------------------------------------------------
  // 1. USERNAME VALIDATION & AVAILABILITY
  // ---------------------------------------------------------------------------
  /// Validate username syntax and check uniqueness against database
  static Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/check-username'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username.trim().toLowerCase()}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      // Local client-side fallback validation
      final clean = username.trim().toLowerCase();
      final reserved = [
        'admin', 'administrator', 'root', 'support', 'wrindha', 'wrindhaos',
        'system', 'moderator', 'api', 'help', 'official', 'auth', 'security', 'guest'
      ];
      if (clean.length < 3 || clean.length > 20) {
        return {'available': false, 'error': 'Username must be between 3 and 20 characters.'};
      }
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(clean)) {
        return {'available': false, 'error': 'Only letters, numbers, and underscores allowed.'};
      }
      if (reserved.contains(clean)) {
        return {'available': false, 'error': 'This username is reserved.'};
      }
      return {'available': true, 'username': clean};
    }
  }

  // ---------------------------------------------------------------------------
  // 2. CREATE ACCOUNT (SIGNUP) WITH EMAIL OTP
  // ---------------------------------------------------------------------------
  /// Step 1: Validate details and send 6-digit Email OTP
  static Future<Map<String, dynamic>> registerInitiate({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim().toLowerCase(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Step 2: Verify OTP and activate user account
  static Future<Map<String, dynamic>> registerVerify({
    required String email,
    required String otp,
    String? username,
    String? password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          if (username != null) 'username': username.trim().toLowerCase(),
          if (password != null) 'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token'] != null) {
        await saveSession(data['token'], data['user']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Verification failed: $e'};
    }
  }

  /// Resend Registration Email OTP
  static Future<Map<String, dynamic>> resendRegistrationOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'type': 'register',
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // 3. LOGIN (USERNAME + PASSWORD)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim().toLowerCase(),
          'password': password,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token'] != null) {
        await saveSession(data['token'], data['user']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: Unable to connect to server.'};
    }
  }

  // ---------------------------------------------------------------------------
  // 4. FORGOT PASSWORD FLOW (EMAIL OTP + CREATE NEW PASSWORD)
  // ---------------------------------------------------------------------------
  /// Step 1: Submit registered email to receive Reset OTP
  static Future<Map<String, dynamic>> forgotPasswordInitiate(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': true,
        'message': 'If an account exists with this email, a verification code has been sent.',
      };
    }
  }

  /// Step 2: Verify 6-digit Password Reset OTP
  static Future<Map<String, dynamic>> forgotPasswordVerifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Verification failed: $e'};
    }
  }

  /// Step 3: Create New Password
  static Future<Map<String, dynamic>> forgotPasswordReset({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to reset password: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // 5. SESSION PERSISTENCE & LOGOUT
  // ---------------------------------------------------------------------------
  static Future<void> saveSession(String token, Map<String, dynamic>? user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (user != null) {
      await prefs.setString(_userKey, jsonEncode(user));
    }
  }

  static Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_userKey);
    if (str == null) return null;
    try {
      return jsonDecode(str);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasActiveSession() async {
    final token = await getSessionToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    try {
      await http.post(Uri.parse('$baseUrl/auth/logout'));
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // 6. SUBSCRIPTION & FEATURE ACCESS API
  // ---------------------------------------------------------------------------
  static Future<UserSubscription?> fetchUserSubscription() async {
    try {
      final token = await getSessionToken();
      final response = await http.get(
        Uri.parse('$baseUrl/subscription/me'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['subscription'] != null) {
          return UserSubscription.fromJson(data['subscription']);
        }
      }
    } catch (_) {}
    return null;
  }
}
