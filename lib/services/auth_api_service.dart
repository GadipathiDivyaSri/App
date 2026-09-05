import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/msg91_config.dart';

class AuthApiService {
  static const Duration timeoutDuration = Duration(seconds: 10);
  static const String _jwtStorageKey = 'wrindha_secure_jwt_token';
  static const String _userStorageKey = 'wrindha_secure_user_profile';

  /// Authenticate with WrindhaOS Backend using MSG91 Widget Access Token
  /// POST /api/v1/auth/msg91/verify
  static Future<Map<String, dynamic>> verifyMsg91AccessToken(
    String accessToken, {
    String? referralCode,
    http.Client? client,
  }) async {
    if (accessToken.trim().isEmpty) {
      return {
        'success': false,
        'message': 'MSG91 access token is required for verification.',
      };
    }

    final httpClient = client ?? http.Client();
    final url = Uri.parse('${Msg91Config.baseUrl}/auth/msg91/verify');

    try {
      final response = await httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'accessToken': accessToken.trim(),
              if (referralCode != null && referralCode.trim().isNotEmpty)
                'referredByCode': referralCode.trim(),
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final sessionData = data['data'];
          final String token = sessionData['token'] ?? '';
          final Map<String, dynamic> userMap = sessionData['user'] ?? {};

          // Store session token and user profile securely
          if (token.isNotEmpty) {
            await saveSessionToken(token);
            await saveCachedUser(userMap);
          }

          return {
            'success': true,
            'message': 'Authentication successful.',
            'token': token,
            'user': userMap,
            'isNewUser': sessionData['isNewUser'] ?? false,
          };
        }
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Invalid authentication request. Please retry sign-in.',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Incorrect or expired OTP. Please try again.',
        };
      } else if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Too many sign-in attempts. Please wait a few minutes.',
        };
      } else {
        return {
          'success': false,
          'message':
              'WrindhaOS authentication is temporarily unavailable. Please try again.',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Connection timed out. Please check your internet connection.',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Unable to connect to WrindhaOS. Check your internet connection.',
      };
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    return {
      'success': false,
      'message': 'Authentication failed. Please try again.',
    };
  }

  /// Secure Storage Helpers
  static Future<void> saveSessionToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedToken = base64Encode(utf8.encode(token));
    await prefs.setString(_jwtStorageKey, encodedToken);
  }

  static Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_jwtStorageKey);
    if (stored == null || stored.isEmpty) return null;
    try {
      return utf8.decode(base64Decode(stored));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCachedUser(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userStorageKey, jsonEncode(userMap));
  }

  static Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userStorageKey);
    if (userJson == null) return null;
    try {
      return jsonDecode(userJson);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_jwtStorageKey);
      await prefs.remove(_userStorageKey);
      await prefs.remove('wrindha_auth_token');
      await prefs.remove('wrindha_auth_user');
      await prefs.remove('saved_session_user');
      await prefs.remove('saved_session_token');
    } catch (_) {}
  }
}
