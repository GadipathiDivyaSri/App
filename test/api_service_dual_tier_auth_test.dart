import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:productivity_app/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiService Dual-Tier Resilient Authentication Tests', () {
    test('1. Reviewer credentials bypass OTP dispatch instantly', () async {
      final res = await ApiService.loginInitiate(email: 'reviewer@wrindha.app');
      expect(res['success'], true);
      expect(res['username'], 'GoogleReviewer');
    });

    test('2. Reviewer credentials static OTP verification establishes session', () async {
      final res = await ApiService.loginVerify(
        email: 'reviewer@wrindha.app',
        otp: '123456',
      );
      expect(res['success'], true);
      expect(res['token'], isNotNull);
      expect(await ApiService.hasActiveSession(), true);
    });

    test('3. Non-existent email returns clear account not found error', () async {
      final res = await ApiService.loginInitiate(email: 'definitely_nonexistent_user_99999@wrindha.test');
      expect(res['success'], false);
      expect(res['message'], contains('No account found'));
    });

    test('4. Existing user triggers fallback and dispatches OTP code', () async {
      final res = await ApiService.loginInitiate(email: 'mungipattudevi@gmail.com');
      expect(res['success'], true);
      expect(res['requiresOtp'], true);
      expect(res['email'], 'mungipattudevi@gmail.com');
      expect(res['username'], isNotEmpty);
    });

    test('5. Invalid OTP code is rejected', () async {
      // First initiate
      await ApiService.loginInitiate(email: 'mungipattudevi@gmail.com');

      // Attempt verify with incorrect code
      final verifyRes = await ApiService.loginVerify(
        email: 'mungipattudevi@gmail.com',
        otp: '000000',
      );
      expect(verifyRes['success'], false);
      expect(verifyRes['message'], contains('Incorrect verification code'));
    });

    test('6. Valid OTP code verifies and establishes active session', () async {
      // Initiate to store pending OTP
      await ApiService.loginInitiate(email: 'mungipattudevi@gmail.com');

      // Inspect mock SharedPreferences for the generated OTP
      final prefs = await SharedPreferences.getInstance();
      final pendingStr = prefs.getString('pending_otp_mungipattudevi@gmail.com');
      expect(pendingStr, isNotNull);
      final pendingData = jsonDecode(pendingStr!);
      final actualOtp = pendingData['otp'].toString();

      // Verify with actual OTP
      final verifyRes = await ApiService.loginVerify(
        email: 'mungipattudevi@gmail.com',
        otp: actualOtp,
      );
      expect(verifyRes['success'], true);
      expect(verifyRes['token'], isNotNull);
      expect(verifyRes['user'], isNotNull);
      expect(await ApiService.hasActiveSession(), true);

      // Verify getCurrentUser validates active session
      final currentUser = await ApiService.getCurrentUser();
      expect(currentUser['success'], true);
      expect(currentUser['user']['email'], 'mungipattudevi@gmail.com');
    });

    test('7. Username availability check via Supabase fallback', () async {
      final res = await ApiService.checkUsername('dileeshbunny');
      expect(res['available'], false);

      final resAvailable = await ApiService.checkUsername('unique_user_unused_${DateTime.now().millisecondsSinceEpoch}');
      expect(resAvailable['available'], true);
    });

    test('8. MSG91 template variables contain exhaustive lowercase and uppercase mappings', () {
      final vars = ApiService.buildMsg91OtpVariables(
        otpCode: '581920',
        recipientName: 'devi',
      );

      // Verify essential Handlebars variable keys
      expect(vars['otp'], '581920', reason: 'Lowercase otp is required by standard MSG91 global_otp template');
      expect(vars['OTP'], '581920', reason: 'Uppercase OTP must match uppercase template variants');
      expect(vars['code'], '581920');
      expect(vars['CODE'], '581920');
      expect(vars['otp_code'], '581920');
      expect(vars['verification_code'], '581920');
      expect(vars['var1'], '581920');
      expect(vars['VAR1'], '581920');
      expect(vars['company_name'], 'WrindhaOS');
      expect(vars['company'], 'WrindhaOS');
      expect(vars['name'], 'Devi');
    });
  });
}

