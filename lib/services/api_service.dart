import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // ---------------------------------------------------------------------------
  // AUTHENTICATION & 2FA OTP
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> send2FAOTP(String contact) async {
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

  static Future<Map<String, dynamic>> verify2FAOTP(
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
