class Msg91Config {
  // MSG91 Widget Configuration
  static const String widgetId = '36687761466f383937303733';
  static const String authKey = '563368T7dxQrK5Wo6a8da71fP1';
  static const String tokenAuthUrl =
      'https://control.msg91.com/api/v5/widget/verifyAccessToken';

  // OTP Rules & Cooldown
  static const int resendIntervalSeconds = 30;
  static const int maxResendCount = 2;
  static const int otpLength = 6;

  // Backend API URL Configuration
  static const String devBaseUrl = 'http://localhost:3000/api';
  static const String prodBaseUrl =
      'https://wrindhaos-backend.onrender.com/api';

  // Active Base URL (Development vs Production)
  static String get baseUrl {
    const isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? prodBaseUrl : devBaseUrl;
  }
}
