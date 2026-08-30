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

  static Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final clean = username.trim().toLowerCase();
      if (clean.length < 3) {
        return {'available': false, 'message': 'Username must be at least 3 characters long.'};
      }
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(clean)) {
        return {'available': false, 'message': 'Only letters, numbers, and underscores are allowed.'};
      }
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-username?username=${Uri.encodeComponent(clean)}'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'available': true};
    } catch (e) {
      return {'available': true};
    }
  }

  static Future<Map<String, dynamic>> registerVerify({
    String? username,
    required String email,
    required String otp,
    String? referralCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (username != null) 'username': username.trim().toLowerCase(),
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

  static Future<Map<String, dynamic>> resendRegistrationOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase(), 'type': 'register'}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to resend code: $e'};
    }
  }

  static Future<Map<String, dynamic>> forgotPasswordInitiate(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to send OTP: $e'};
    }
  }

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

  static Future<Map<String, dynamic>> deleteAccount({
    String? userId,
    String? contact,
    String? token,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await clearSession();
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Account deletion failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> createExpense({
    required String title,
    required String category,
    required double amount,
    bool isIncome = false,
    String paymentMethod = 'UPI',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'category': category,
          'amount': amount,
          'isIncome': isIncome,
          'paymentMethod': paymentMethod,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Expense record failed: $e'};
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
  // 6. HABIT TRACKER REST APIS (Production-Ready Backend Sync)
  // ---------------------------------------------------------------------------

  /// Fetch user's habits with streak & completion status for a specific date
  static Future<List<Habit>> fetchHabits({String? date}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/habits').replace(queryParameters: date != null ? {'date': date} : null);
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => Habit.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Create Habit with Free tier enforcement (Max 2 Habits)
  static Future<Map<String, dynamic>> createHabitOnBackend(Habit habit) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/habits'),
        headers: headers,
        body: jsonEncode(habit.toJson()),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  /// Update existing Habit
  static Future<Map<String, dynamic>> updateHabitOnBackend(Habit habit) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/habits/${habit.id}'),
        headers: headers,
        body: jsonEncode(habit.toJson()),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  /// Delete Habit and cascade completion records
  static Future<Map<String, dynamic>> deleteHabitOnBackend(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/habits/$habitId'),
        headers: headers,
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  /// Pause, Resume, or Archive a Habit
  static Future<Map<String, dynamic>> updateHabitStatusOnBackend(String habitId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/habits/$habitId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  static Future<Map<String, dynamic>> pauseHabitOnBackend(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse('$baseUrl/habits/$habitId/pause'), headers: headers);
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  static Future<Map<String, dynamic>> resumeHabitOnBackend(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse('$baseUrl/habits/$habitId/resume'), headers: headers);
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  static Future<Map<String, dynamic>> archiveHabitOnBackend(String habitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse('$baseUrl/habits/$habitId/archive'), headers: headers);
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  /// Toggle habit completion for a specific date
  static Future<Map<String, dynamic>> toggleHabitCompletionOnBackend(
    String habitId, {
    required String date,
    bool? isCompleted,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/habits/$habitId/toggle'),
        headers: headers,
        body: jsonEncode({
          'date': date,
          if (isCompleted != null) 'status': isCompleted ? 'completed' : 'uncompleted',
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  /// Fetch habit analytics summary
  static Future<Map<String, dynamic>> fetchHabitAnalytics({String? date}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/habits/analytics').replace(queryParameters: date != null ? {'date': date} : null);
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {'success': false};
  }

  /// Fetch rule-based Smart Assistant habit insights
  static Future<List<Map<String, dynamic>>> fetchHabitInsights({String? date}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/habits/insights').replace(queryParameters: date != null ? {'date': date} : null);
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch habit historical status matrix
  static Future<List<Map<String, dynamic>>> fetchHabitHistory(String habitId, {int days = 30}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/habits/$habitId/history').replace(queryParameters: {'days': days.toString()});
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (_) {}
    return [];
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
