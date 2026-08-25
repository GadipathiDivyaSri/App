class Msg91Config {
  // MSG91 Widget Configuration
  static const String widgetId = 'your_msg91_widget_id';
  static const String tokenAuthUrl =
      'https://control.msg91.com/api/v5/widget/verifyAccessToken';

  // Backend API URL Configuration
  static const String devBaseUrl = 'http://localhost:5000/api/v1';
  static const String prodBaseUrl =
      'https://wrindhaos-backend.onrender.com/api/v1';

  // Active Base URL (Development vs Production)
  static String get baseUrl {
    const isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? prodBaseUrl : devBaseUrl;
  }
}
