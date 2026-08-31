import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';
import 'screens/auth_entry_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: const Color(0xFFFFF9F0),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Text(
          'Rendering notice: ${details.exceptionAsString()}',
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12),
        ),
      ),
    );
  };
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const ProductivityApp(),
    ),
  );
}

class ProductivityApp extends StatelessWidget {
  const ProductivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return MaterialApp(
      title: 'Wrindha OS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: provider.isLoggedIn
          ? const MainNavigationScreen()
          : const AuthEntryScreen(),
    );
  }
}
