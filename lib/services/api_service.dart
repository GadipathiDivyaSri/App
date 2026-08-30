import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Centralized REST API Service for WrindhaOS
class ApiService {
  // Production default endpoint with fallback capability
  static String baseUrl = 'http://localhost:8080/api';

  static const String _tokenKey = 'wrindha_auth_token';
  static const String _userKey = 'wrindha_auth_user';

  /// Helper to generate authenticated HTTP headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getSessionToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------------------------
  // 1. AUTHENTICATION SERVICES
  // ---------------------------------------------------------------------------
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
      return {'success': false, 'message': 'Network error: Unable to connect to server.'};
    }
  }

  static Future<Map<String, dynamic>> registerVerify({
    required String email,
    required String otp,
    String? referralCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          if (referralCode != null) 'referralCode': referralCode.trim(),
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

  static Future<Map<String, dynamic>> googleLogin({
    required String email,
    required String googleId,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'googleId': googleId,
          'name': name,
          'photoUrl': photoUrl,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token'] != null) {
        await saveSession(data['token'], data['user']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Google Sign-In failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> fetchSession() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/auth/session'), headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Session verification error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse('$baseUrl/users/me'), headers: headers);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await clearSession();
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Account deletion failed: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // 2. SESSION & STORAGE
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

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ---------------------------------------------------------------------------
  // 3. SUBSCRIPTION & PAYMENTS
  // ---------------------------------------------------------------------------
  static Future<UserSubscription?> fetchUserSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/subscription/me'), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['subscription'] != null) {
          return UserSubscription.fromJson(data['subscription']);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> upgradeSubscription({String provider = 'GOOGLE_PLAY'}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/subscription/upgrade'),
        headers: headers,
        body: jsonEncode({'provider': provider}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Upgrade failed: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // 4. COUPON & PROMOTIONAL SYSTEM
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> validateCoupon(String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/coupons/validate'),
        headers: headers,
        body: jsonEncode({'code': code.trim().toUpperCase()}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Coupon validation failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> applyCoupon(String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/coupons/apply'),
        headers: headers,
        body: jsonEncode({'code': code.trim().toUpperCase()}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Applying coupon failed: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // 5. REFERRAL SYSTEM
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> fetchMyReferralCode() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/referrals/my-code'), headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Fetching referral code failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> applyReferralCode(String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/referrals/apply-code'),
        headers: headers,
        body: jsonEncode({'code': code.trim().toUpperCase()}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Applying referral code failed: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // 6. MODULE REST APIS (Habits, Subjects, Tasks, Goals, Expenses, etc.)
  // ---------------------------------------------------------------------------

  /// Habits API (Free plan limit: Max 2 Habits)
  static Future<Map<String, dynamic>> createHabitOnBackend(String title, String frequency) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/habits'),
        headers: headers,
        body: jsonEncode({'title': title, 'frequency': frequency}),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  /// Subjects API (Free plan limit: Max 2 Subjects)
  static Future<Map<String, dynamic>> createSubjectOnBackend(String name, String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/subjects'),
        headers: headers,
        body: jsonEncode({'name': name, 'code': code}),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  /// Pro Goal Creation API
  static Future<Map<String, dynamic>> createGoalOnBackend(String title, String tier) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/goals'),
        headers: headers,
        body: jsonEncode({'title': title, 'tier': tier}),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  /// Real Dynamic Analytics Summary
  static Future<Map<String, dynamic>> fetchAnalyticsSummary() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/analytics/summary'), headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Analytics fetch error: $e'};
    }
  }
}
