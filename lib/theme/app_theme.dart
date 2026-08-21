import 'package:flutter/material.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // LIGHT MODE PALETTE (Warm Cozy Pastel - Refer to Image 2)
  // ---------------------------------------------------------------------------
  static const Color lightBg = Color(0xFFFFF9F0); // Warm Cream / Oat Milk
  static const Color lightPrimary = Color(0xFFE87552); // Coral / Terracotta Accent
  static const Color lightTextPrimary = Color(0xFF2D2622); // Deep Espresso
  static const Color lightTextSecondary = Color(0xFF8D827A); // Muted Warm Taupe
  static const Color lightCardWhite = Colors.white;
  static const Color lightNavBg = Colors.white;

  // Light Mode Module Pastel Card Colors
  static const Color pastelPersonalGrowth = Color(0xFFCFE8D5); // Sage Mint
  static const Color pastelPersonalGrowthIcon = Color(0xFF4A9B65);

  static const Color pastelCareer = Color(0xFFF7C6B0); // Soft Peach
  static const Color pastelCareerIcon = Color(0xFFE87552);

  static const Color pastelStudies = Color(0xFFF8DFA6); // Buttercup Yellow
  static const Color pastelStudiesIcon = Color(0xFFDCA432);

  static const Color pastelCalendar = Color(0xFFDCC9E8); // Lavender Violet
  static const Color pastelCalendarIcon = Color(0xFF9369BE);

  static const Color pastelPriority = Color(0xFFE8B8BC); // Blush Pink
  static const Color pastelPriorityIcon = Color(0xFFD25B67);

  static const Color pastelAnalytics = Color(0xFFC4D9E8); // Sky Blue
  static const Color pastelAnalyticsIcon = Color(0xFF4B8DBA);

  // ---------------------------------------------------------------------------
  // DARK MODE PALETTE (Deep Navy / Midnight Glow - Refer to Image 1)
  // ---------------------------------------------------------------------------
  static const Color darkBg = Color(0xFF060B1E); // Deep Navy Canvas
  static const Color darkCardBg = Color(0xFF0D1B3E); // Glowing Navy Card
  static const Color darkCardBorder = Color(0x332A85FF); // Subtle Electric Blue Border
  static const Color darkPrimary = Color(0xFF2563EB); // Electric Royal Blue
  static const Color darkIconGlow = Color(0xFF2A85FF); // Glowing Cyan/Blue Icon
  static const Color darkIconBg = Color(0xFF132F5C); // Squircle Container
  static const Color darkTextPrimary = Colors.white; // Crisp White
  static const Color darkTextSecondary = Color(0xFF7E97B8); // Muted Steel Blue
  static const Color darkNavBg = Color(0xFF070D22); // Dark Navy Bar

  // ---------------------------------------------------------------------------
  // THEME DATA DEFINITIONS
  // ---------------------------------------------------------------------------
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    primaryColor: lightPrimary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: lightPrimary,
      brightness: Brightness.light,
      surface: lightBg,
      primary: lightPrimary,
      secondary: const Color(0xFFE87552),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: lightCardWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: darkPrimary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
      surface: darkBg,
      primary: darkPrimary,
      secondary: darkIconGlow,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: darkCardBorder, width: 1),
      ),
    ),
  );
}
