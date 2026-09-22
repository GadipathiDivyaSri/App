import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:productivity_app/providers/app_provider.dart';
import 'package:productivity_app/screens/email_otp_screen.dart';
import 'package:productivity_app/screens/password_reset_otp_screen.dart';
import 'package:productivity_app/screens/login_screen.dart';
import 'package:productivity_app/screens/signup_screen.dart';
import 'package:productivity_app/screens/referral_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final viewports = [
    const Size(320, 568),  // iPhone SE (1st gen) - 320px
    const Size(360, 640),  // Standard Android - 360px
    const Size(375, 667),  // iPhone 8 / SE 2nd gen - 375px
    const Size(390, 844),  // iPhone 12/13/14 - 390px
    const Size(414, 896),  // iPhone 11 / XR - 414px
    const Size(430, 932),  // iPhone 14/15 Pro Max - 430px
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child, AppProvider provider) {
    return ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  for (final size in viewports) {
    group('Viewport Responsiveness: ${size.width.toInt()}px x ${size.height.toInt()}px', () {
      testWidgets('PasswordResetOtpScreen renders without horizontal overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final provider = AppProvider();
        await tester.pumpWidget(buildTestableWidget(
          const PasswordResetOtpScreen(email: 'student@example.com'),
          provider,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Must not overflow at width ${size.width}');
        expect(find.byType(PasswordResetOtpScreen), findsOneWidget);
      });

      testWidgets('EmailOtpScreen (Login) renders without horizontal overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final provider = AppProvider();
        await tester.pumpWidget(buildTestableWidget(
          const EmailOtpScreen(email: 'student@example.com', isLogin: true),
          provider,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Must not overflow at width ${size.width}');
        expect(find.byType(EmailOtpScreen), findsOneWidget);
      });

      testWidgets('LoginScreen renders without horizontal overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final provider = AppProvider();
        await tester.pumpWidget(buildTestableWidget(
          const LoginScreen(),
          provider,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Must not overflow at width ${size.width}');
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('SignUpScreen renders without horizontal overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final provider = AppProvider();
        await tester.pumpWidget(buildTestableWidget(
          const SignUpScreen(),
          provider,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Must not overflow at width ${size.width}');
        expect(find.byType(SignUpScreen), findsOneWidget);
      });

      testWidgets('ReferralScreen renders without horizontal overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final provider = AppProvider();
        await tester.pumpWidget(buildTestableWidget(
          const ReferralScreen(),
          provider,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Must not overflow at width ${size.width}');
        expect(find.byType(ReferralScreen), findsOneWidget);
      });
    });
  }
}
