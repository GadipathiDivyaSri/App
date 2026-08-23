import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // ---------------------------------------------------------------------------
  // AUTHENTICATION & OTP
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> sendOTP(String contact) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contact': contact}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to connect to backend: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyOTP(
      String contact, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contact': contact, 'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Verification failed: $e'};
    }
  }

  // Backward compatibility alias
  static Future<Map<String, dynamic>> send2FAOTP(String contact) => sendOTP(contact);
  static Future<Map<String, dynamic>> verify2FAOTP(String contact, String code) => verifyOTP(contact, code);

  static Future<Map<String, dynamic>> googleSignIn(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'googleToken': token}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Google Sign-In failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteAccount({
    String? userId,
    String? contact,
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/user/delete-account'),
        headers: headers,
        body: jsonEncode({
          if (userId != null) 'userId': userId,
          if (contact != null) 'contact': contact,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          return jsonDecode(response.body);
        } catch (_) {
          return {
            'success': false,
            'message': 'Failed to delete account (Status: ${response.statusCode})',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to backend: $e',
      };
    }
  }

  // ---------------------------------------------------------------------------
  // TASKS API
  // ---------------------------------------------------------------------------
  static Future<List<dynamic>> fetchTasks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['tasks'] ?? [];
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    }
    return [];
  }

  static Future<bool> createTask(
      String title, String category, String dueDateLabel) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'category': category,
          'dueDateLabel': dueDateLabel,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error creating task: $e');
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // EXPENSES API
  // ---------------------------------------------------------------------------
  static Future<List<dynamic>> fetchExpenses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/expenses'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['expenses'] ?? [];
      }
    } catch (e) {
      print('Error fetching expenses: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> createExpense({
    required String title,
    required String category,
    required double amount,
    bool isIncome = false,
    String paymentMethod = 'UPI',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: {'Content-Type': 'application/json'},
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
      return {'success': false, 'message': 'Failed to create expense: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateExpense({
    required String id,
    required String title,
    required String category,
    required double amount,
    bool isIncome = false,
    String paymentMethod = 'UPI',
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: {'Content-Type': 'application/json'},
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
      return {'success': false, 'message': 'Failed to update expense: $e'};
    }
  }

  static Future<bool> deleteExpense(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/expenses/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // CALENDAR & DATE RESTRICTIONS
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> createCalendarEvent({
    required String title,
    required String description,
    required DateTime date,
    required String startTime,
    required String endTime,
    String location = 'Workspace A',
    String type = 'Focus Session',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calendar/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'date': date.toIso8601String(),
          'startTime': startTime,
          'endTime': endTime,
          'location': location,
          'type': type,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to schedule event: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // REFERRAL SYSTEM & SUBSCRIPTION CHECKOUT
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> fetchReferralSummary(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/referrals/me?userId=$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching referral summary: $e');
    }
    return {'success': false};
  }

  static Future<Map<String, dynamic>> applyReferralCode(
      String userId, String referralCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/referrals/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'referralCode': referralCode}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to apply referral code: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkoutSubscription({
    required String userId,
    required String plan,
    required double basePrice,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'plan': plan,
          'basePrice': basePrice,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Checkout failed: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // ADMOB REWARDS & FCM NOTIFICATIONS
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> claimAdMobReward(int xpAmount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admob/claim-reward'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': xpAmount}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }
}
