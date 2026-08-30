import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/msg91_config.dart';

class ApiService {
  static String get baseUrl => Msg91Config.baseUrl;

  // ---------------------------------------------------------------------------
  // AUTHENTICATION & OTP
  // ---------------------------------------------------------------------------

  /// Checks username availability, format rules, and reserved keywords
  static Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/check-username'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'available': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkUsername(String username) =>
      checkUsernameAvailability(username);

  /// Create Account Step 1 & 2: Validate details & initiate 6-digit Email OTP
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
          'username': username,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to connect to server: $e'};
    }
  }

  /// Step 3: Verify 6-digit Email OTP & complete account creation
  static Future<Map<String, dynamic>> verifyEmailOTP({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Verification failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtpAndRegister({
    required String email,
    required String code,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'username': username,
          'password': password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Registration verification failed: $e'};
    }
  }

  /// Resend 6-digit Email OTP with cooldown enforcement
  static Future<Map<String, dynamic>> resendEmailOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to resend OTP: $e'};
    }
  }

  /// Login with Username/Email + Password
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'username': identifier, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Login connection failed: $e'};
    }
  }

  /// Backward compatibility sendOTP / verifyOTP
  static Future<Map<String, dynamic>> sendOTP(String contact) =>
      resendEmailOTP(contact);

  static Future<Map<String, dynamic>> verifyOTP(String contact, String code) =>
      verifyEmailOTP(email: contact, code: code);

  static Future<Map<String, dynamic>> send2FAOTP(String contact) =>
      sendOTP(contact);

  static Future<Map<String, dynamic>> verify2FAOTP(String contact, String code) =>
      verifyOTP(contact, code);

  /// Forgot Password Step 1: Initiate reset by identifier (username or email)
  static Future<Map<String, dynamic>> forgotPasswordInitiate(String identifier) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Password reset request failed: $e'};
    }
  }

  /// Forgot Password Step 2: Verify reset OTP
  static Future<Map<String, dynamic>> forgotPasswordVerify({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'OTP verification failed: $e'};
    }
  }

  /// Forgot Password Step 3: Set new password
  static Future<Map<String, dynamic>> forgotPasswordReset({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Password update failed: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // USER ACCOUNT ACTIONS
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> deleteAccount(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/delete-account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete account: $e'};
    }
  }
}
