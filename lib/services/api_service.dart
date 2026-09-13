import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Centralized REST API Service for WrindhaOS
class ApiService {
  // Production default endpoint with fallback capability
  static String baseUrl = 'https://wrindhaosapp.vercel.app/api';

  static const String _tokenKey = 'wrindha_auth_token';
  static const String _userKey = 'wrindha_auth_user';
  static String? currentOtpSession;

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
    String? referralCode,
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
          if (referralCode != null && referralCode.trim().isNotEmpty)
            'referralCode': referralCode.trim().toUpperCase(),
        }),
      );
      final data = jsonDecode(response.body);
      if (data['otpSession'] != null) {
        currentOtpSession = data['otpSession'];
      }
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: Unable to connect to server ($e)',
      };
    }
  }

  static Future<Map<String, dynamic>> validateReferralCode(String code) async {
    try {
      final clean = code.trim().toUpperCase();
      if (clean.isEmpty) {
        return {'valid': false, 'message': 'Please enter a referral code.'};
      }
      final response = await http.get(
        Uri.parse('$baseUrl/auth/validate-referral?code=${Uri.encodeComponent(clean)}'),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'valid': false, 'message': 'Error validating referral code.'};
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

  static Future<Map<String, dynamic>> checkUsernameAvailability(String username) =>
      checkUsername(username);

  static Future<Map<String, dynamic>> registerVerify({
    String? username,
    required String email,
    required String otp,
    String? referralCode,
    String? otpSession,
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
          'otpSession': otpSession ?? currentOtpSession,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token'] != null) {
        await saveSession(data['token'], data['user']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Unable to connect to authentication server: $e'};
    }
  }

  static Future<Map<String, dynamic>> googleCompleteRegistration({
    required String email,
    required String name,
    required String googleId,
    required String username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'name': name.trim(),
          'googleId': googleId,
          'username': username.trim().toLowerCase(),
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token'] != null) {
        await saveSession(data['token'], data['user']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Registration error: $e'};
    }
  }

  /// Verify MSG91 Widget JWT Access Token with backend
  static Future<Map<String, dynamic>> verifyMsg91AccessToken({
    required String accessToken,
    String? referralCode,
    String? username,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/msg91/verify-access-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access-token': accessToken.trim(),
          if (referralCode != null) 'referralCode': referralCode.trim(),
          if (username != null) 'username': username.trim(),
          if (email != null) 'email': email.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['token'] != null) {
        await saveSession(data['token'], data['user']);
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'MSG91 Token Verification error: $e'};
    }
  }

  static Future<Map<String, dynamic>> resendRegistrationOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase(), 'type': 'register'}),
      );
      final data = jsonDecode(response.body);
      if (data['otpSession'] != null) {
        currentOtpSession = data['otpSession'];
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: Unable to connect to server ($e)'};
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
      return {'success': false, 'message': 'Network error: Unable to connect to server ($e)'};
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
      return {'success': false, 'message': 'Network error: Unable to connect to server ($e)'};
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
      return {'success': false, 'message': 'Network error: Unable to connect to server ($e)'};
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
      return {'success': false, 'message': 'Network error: Unable to connect to server ($e)'};
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
      final user = await getSessionUser();
      if (user != null) {
        return {'success': true, 'user': user};
      }
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


  // ---------------------------------------------------------------------------
  // 2. SESSION & STORAGE
  // ---------------------------------------------------------------------------
  static Future<void> saveSession(String token, Map<String, dynamic>? user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString('saved_session_token', token);
    await prefs.setString('wrindha_secure_jwt_token', token);
    if (user != null) {
      final userCopy = Map<String, dynamic>.from(user);
      userCopy['token'] ??= token;
      final userJson = jsonEncode(userCopy);
      await prefs.setString(_userKey, userJson);
      await prefs.setString('saved_session_user', userJson);
      await prefs.setString('wrindha_secure_user_profile', userJson);
    }
  }

  static Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) ??
        prefs.getString('saved_session_token') ??
        prefs.getString('wrindha_secure_jwt_token');
  }

  static Future<Map<String, dynamic>?> getSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_userKey) ??
        prefs.getString('saved_session_user') ??
        prefs.getString('wrindha_secure_user_profile');
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove('saved_session_user');
      await prefs.remove('saved_session_token');
      await prefs.remove('wrindha_secure_jwt_token');
      await prefs.remove('wrindha_secure_user_profile');
    } catch (_) {}
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

  /// Subjects API (Free plan limit: Max 2 Subjects)
  static Future<Map<String, dynamic>> createSubjectOnBackend(dynamic nameOrSubject, [String? code]) async {
    try {
      final headers = await _getHeaders();
      Map<String, dynamic> payload;
      if (nameOrSubject is StudySubject) {
        payload = nameOrSubject.toJson();
      } else {
        payload = {'name': nameOrSubject.toString(), 'code': code ?? ''};
      }
      final response = await http.post(
        Uri.parse('$baseUrl/subjects'),
        headers: headers,
        body: jsonEncode(payload),
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
  static Future<List<Goal>> fetchGoals({String? tier}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/goals').replace(queryParameters: tier != null ? {'tier': tier} : null);
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => Goal.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> createGoalOnBackend(dynamic goalOrTitle, [String? tier]) async {
    try {
      final headers = await _getHeaders();
      Map<String, dynamic> payload;
      if (goalOrTitle is Goal) {
        payload = goalOrTitle.toJson();
      } else {
        payload = {'title': goalOrTitle.toString(), 'tier': (tier ?? 'short').toLowerCase()};
      }
      final response = await http.post(
        Uri.parse('$baseUrl/goals'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  static Future<Map<String, dynamic>> updateGoalOnBackend(Goal goal) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/goals/${goal.id}'),
        headers: headers,
        body: jsonEncode(goal.toJson()),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  static Future<Map<String, dynamic>> deleteGoalOnBackend(String goalId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/goals/$goalId'),
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

  /// Career Roadmap Node backend sync
  static Future<Map<String, dynamic>> createCareerNodeOnBackend(CareerRoadmapNode node) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/career-roadmap'),
        headers: headers,
        body: jsonEncode({
          'id': node.id,
          'title': node.title,
          'description': node.description,
          'section': node.section,
          'tier': 'long',
          'is_completed': node.isCompleted,
        }),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  static Future<Map<String, dynamic>> updateCareerNodeOnBackend(CareerRoadmapNode node) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/career-roadmap/${node.id}'),
        headers: headers,
        body: jsonEncode({
          'title': node.title,
          'description': node.description,
          'section': node.section,
          'is_completed': node.isCompleted,
        }),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  static Future<Map<String, dynamic>> deleteCareerNodeOnBackend(String nodeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/career-roadmap/$nodeId'),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'success': false, 'message': '$e'}};
    }
  }

  static Future<List<CareerRoadmapNode>> fetchCareerRoadmapNodes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/career-roadmap'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => CareerRoadmapNode.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
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

  // ---------------------------------------------------------------------------
  // 7. TASKS REST APIS (Production-Ready Cloud Sync)
  // ---------------------------------------------------------------------------
  static Future<List<Task>> fetchTasks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/tasks'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => Task.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> createTaskOnBackend(Task task) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: jsonEncode({
          'id': task.id,
          'title': task.title,
          'category': task.category,
          'priority': task.priority,
          'dueDate': task.dueDate.toIso8601String(),
          'due_date': task.dueDate.toIso8601String(),
          'dueDateLabel': task.dueDateLabel,
          'isCompleted': task.isCompleted,
          'is_completed': task.isCompleted,
        }),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  static Future<Map<String, dynamic>> updateTaskOnBackend(Task task) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/${task.id}'),
        headers: headers,
        body: jsonEncode({
          'title': task.title,
          'category': task.category,
          'priority': task.priority,
          'dueDate': task.dueDate.toIso8601String(),
          'due_date': task.dueDate.toIso8601String(),
          'dueDateLabel': task.dueDateLabel,
          'isCompleted': task.isCompleted,
          'is_completed': task.isCompleted,
        }),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  static Future<Map<String, dynamic>> deleteTaskOnBackend(String taskId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: headers,
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  // ---------------------------------------------------------------------------
  // 8. EXPENSES REST APIS (Production-Ready Cloud Sync)
  // ---------------------------------------------------------------------------
  static Future<List<ExpenseTransaction>> fetchExpenses() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/expenses'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => ExpenseTransaction.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> createExpense({
    required String title,
    required String category,
    required double amount,
    bool isIncome = false,
    String paymentMethod = 'UPI',
    String? id,
    DateTime? date,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: headers,
        body: jsonEncode({
          if (id != null) 'id': id,
          'title': title,
          'category': category,
          'amount': amount,
          'isIncome': isIncome,
          'is_income': isIncome,
          'paymentMethod': paymentMethod,
          'payment_method': paymentMethod,
          'occurred_at': (date ?? DateTime.now()).toIso8601String(),
          'date': (date ?? DateTime.now()).toIso8601String(),
        }),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  static Future<Map<String, dynamic>> createExpenseOnBackend(ExpenseTransaction expense) async {
    return createExpense(
      id: expense.id,
      title: expense.title,
      category: expense.category,
      amount: expense.amount,
      isIncome: expense.isIncome,
      paymentMethod: expense.paymentMethod,
      date: expense.date,
    );
  }

  static Future<Map<String, dynamic>> deleteExpenseOnBackend(String expenseId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$expenseId'),
        headers: headers,
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  // ---------------------------------------------------------------------------
  // 9. SUBJECTS REST APIS (Production-Ready Cloud Sync)
  // ---------------------------------------------------------------------------
  static Future<List<StudySubject>> fetchSubjects() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/subjects'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => StudySubject.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> deleteSubjectOnBackend(String subjectId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/subjects/$subjectId'),
        headers: headers,
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  static Future<Map<String, dynamic>> updateSubjectOnBackend(StudySubject subject) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/subjects/${subject.id}'),
        headers: headers,
        body: jsonEncode(subject.toJson()),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  // ---------------------------------------------------------------------------
  // 9B. STUDY ITEMS REST APIS (Production-Ready Cloud Sync)
  // ---------------------------------------------------------------------------
  static Future<List<StudyItem>> fetchStudyItems({String? subjectId}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/study-items').replace(
        queryParameters: subjectId != null ? {'subjectId': subjectId} : null,
      );
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => StudyItem.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> createStudyItemOnBackend(StudyItem item) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/study-items'),
        headers: headers,
        body: jsonEncode(item.toJson()),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  static Future<Map<String, dynamic>> updateStudyItemOnBackend(StudyItem item) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/study-items/${item.id}'),
        headers: headers,
        body: jsonEncode(item.toJson()),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  static Future<Map<String, dynamic>> deleteStudyItemOnBackend(String itemId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/study-items/$itemId'),
        headers: headers,
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  // ---------------------------------------------------------------------------
  // 10. CALENDAR EVENTS REST APIS (Production-Ready Cloud Sync)
  // ---------------------------------------------------------------------------
  static Future<List<CalendarEvent>> fetchCalendarEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/calendar'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => CalendarEvent.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> createCalendarEventOnBackend(CalendarEvent event) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/calendar'),
        headers: headers,
        body: jsonEncode({
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'startTime': event.startTime.toIso8601String(),
          'endTime': event.endTime.toIso8601String(),
          'start_time': event.startTime.toIso8601String(),
          'end_time': event.endTime.toIso8601String(),
          'location': event.location,
          'type': event.type,
          'category': event.category,
        }),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  static Future<Map<String, dynamic>> deleteCalendarEventOnBackend(String eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/calendar/$eventId'),
        headers: headers,
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  // ---------------------------------------------------------------------------
  // 11. JOURNAL ENTRIES REST APIS (Production-Ready Cloud Sync)
  // ---------------------------------------------------------------------------
  static Future<List<JournalEntry>> fetchJournalEntries() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/journal'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => JournalEntry.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> createJournalEntryOnBackend(JournalEntry entry) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/journal'),
        headers: headers,
        body: jsonEncode(entry.toJson()),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  static Future<Map<String, dynamic>> updateJournalEntryOnBackend(JournalEntry entry) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/journal/${entry.id}'),
        headers: headers,
        body: jsonEncode(entry.toJson()),
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  static Future<Map<String, dynamic>> deleteJournalEntryOnBackend(String journalId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/journal/$journalId'),
        headers: headers,
      );
      return {'statusCode': response.statusCode, 'data': jsonDecode(response.body)};
    } catch (e) {
      return {'statusCode': 500, 'data': {'error': e.toString()}};
    }
  }

  // ---------------------------------------------------------------------------
  // 12. USER PROFILE CLOUD SYNC
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> fetchUserProfileFromBackend() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/users/me'), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {'success': false};
  }

  static Future<Map<String, dynamic>> updateUserProfileOnBackend(Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
        body: jsonEncode(updates),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

