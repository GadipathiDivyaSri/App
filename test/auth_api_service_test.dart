import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:productivity_app/services/auth_api_service.dart';
import 'package:productivity_app/services/msg91_service.dart';
import 'package:productivity_app/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Flutter MSG91 & AuthApiService Integration Tests', () {
    test('1. Msg91Service sends OTP to valid email', () async {
      final res = await Msg91Service.sendEmailOtp('student@wrindhaos.com');
      expect(res['success'], true);
      expect(res['message'], contains('student@wrindhaos.com'));
    });

    test('2. Msg91Service rejects empty email', () async {
      final res = await Msg91Service.sendEmailOtp('');
      expect(res['success'], false);
    });

    test('3. Msg91Service verifies OTP and returns accessToken', () async {
      final res = await Msg91Service.verifyOtp(
        email: 'student@wrindhaos.com',
        otp: '1234',
      );
      expect(res['success'], true);
      expect(res['accessToken'], isNotNull);
      expect(res['accessToken'], contains('test_msg91_token_student@wrindhaos.com'));
    });

    test('4. AuthApiService rejects empty accessToken', () async {
      final res = await AuthApiService.verifyMsg91AccessToken('');
      expect(res['success'], false);
      expect(res['message'], contains('required'));
    });

    test('5. AuthApiService handles HTTP 200 success response & stores JWT', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['accessToken'], 'valid_access_token_123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'MSG91 Email authentication verified successfully.',
            'data': {
              'user': {
                'id': 'u_test_999',
                'full_name': 'Test Student',
                'email': 'student@wrindhaos.com',
                'subscription_plan': 'FREE',
                'subscription_status': 'ACTIVE',
                'ads_enabled': true,
                'referral_code': 'WRINDHA888',
              },
              'token': 'mock_wrindha_jwt_token_xyz',
              'isNewUser': false,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final res = await AuthApiService.verifyMsg91AccessToken(
        'valid_access_token_123',
        client: mockClient,
      );

      expect(res['success'], true);
      expect(res['token'], 'mock_wrindha_jwt_token_xyz');
      expect(res['user']['email'], 'student@wrindhaos.com');

      // Verify token was stored
      final storedToken = await AuthApiService.getSessionToken();
      expect(storedToken, 'mock_wrindha_jwt_token_xyz');

      final cachedUser = await AuthApiService.getCachedUser();
      expect(cachedUser?['id'], 'u_test_999');
    });

    test('6. AuthApiService handles HTTP 400 Bad Request', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'VALIDATION_ERROR', 'message': 'Missing token'},
          }),
          400,
        );
      });

      final res = await AuthApiService.verifyMsg91AccessToken('bad_token', client: mockClient);
      expect(res['success'], false);
      expect(res['message'], contains('Invalid authentication request'));
    });

    test('7. AuthApiService handles HTTP 401 Unauthorized (Invalid/Expired OTP token)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'INVALID_MSG91_TOKEN', 'message': 'Expired token'},
          }),
          401,
        );
      });

      final res = await AuthApiService.verifyMsg91AccessToken('expired_token', client: mockClient);
      expect(res['success'], false);
      expect(res['message'], contains('Incorrect or expired OTP'));
    });

    test('8. AuthApiService handles HTTP 500 Server Error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final res = await AuthApiService.verifyMsg91AccessToken('any_token', client: mockClient);
      expect(res['success'], false);
      expect(res['message'], contains('temporarily unavailable'));
    });

    test('9. AppProvider sets authenticated session and restores correctly', () async {
      final provider = AppProvider();
      provider.setAuthenticatedSession(
        userMap: {
          'id': 'u_session_user',
          'full_name': 'Authenticated Student',
          'email': 'student@wrindhaos.com',
          'subscription_plan': 'PREMIUM',
          'active_streak': 5,
          'focus_score': 85,
        },
        token: 'stored_jwt_token_abc',
      );

      expect(provider.isLoggedIn, true);
      expect(provider.user.name, 'Authenticated Student');
      expect(provider.user.contact, 'student@wrindhaos.com');
      expect(provider.user.isPremium, true);

      // Test Logout clears session
      await provider.logout();
      expect(provider.isLoggedIn, false);

      final tokenAfterLogout = await AuthApiService.getSessionToken();
      expect(tokenAfterLogout, isNull);
    });
  });
}
