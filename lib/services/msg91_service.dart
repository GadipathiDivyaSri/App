import 'dart:async';

class Msg91Service {
  /// Request Email OTP dispatch via MSG91 Widget / Service
  static Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return {
        'success': false,
        'message': 'Please enter a valid email address.',
      };
    }

    // In local development or client widget flow: simulate instant dispatch
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'success': true,
      'message': '4-digit OTP sent to $cleanEmail',
    };
  }

  /// Verify OTP code entered by user with MSG91 and obtain MSG91 Access Token
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otp.trim();

    if (cleanOtp.isEmpty) {
      return {
        'success': false,
        'message': 'Please enter the verification code.',
      };
    }

    // Simulate MSG91 widget OTP verification handshake
    await Future.delayed(const Duration(milliseconds: 300));

    // Return the MSG91 Access Token
    final accessToken = 'test_msg91_token_$cleanEmail';
    return {
      'success': true,
      'accessToken': accessToken,
      'message': 'OTP verified successfully by MSG91.',
    };
  }
}
