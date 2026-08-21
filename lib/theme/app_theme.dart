import 'package:flutter/material.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // EXACT LIGHT MODE SPECIFICATION PALETTE (From Reference Image)
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFFFFF9F0); // Main Light Background
  static const Color primaryAccent = Color(0xFFE87552); // Coral / Terracotta Accent

  // Module Pastel Colors
  static const Color personalGrowth = Color(0xFFCFE8D5); // Sage Mint
  static const Color career = Color(0xFFF7C6B0); // Soft Peach
  static const Color studies = Color(0xFFF8DFA6); // Buttercup Yellow
  static const Color calendar = Color(0xFFDCC9E8); // Lavender Violet
  static const Color priority = Color(0xFFE8B8BC); // Blush Pink
  static const Color analytics = Color(0xFFC4D9E8); // Sky Blue

  // Module Icon Containers & Accents
  static const Color personalGrowthIcon = Color(0xFF4A9B65);
  static const Color careerIcon = Color(0xFFE87552);
  static const Color studiesIcon = Color(0xFFDCA432);
  static const Color calendarIcon = Color(0xFF9369BE);
  static const Color priorityIcon = Color(0xFFD25B67);
  static const Color analyticsIcon = Color(0xFF4B8DBA);

  // Typography & Neutrals
  static const Color textPrimary = Color(0xFF2D2622); // Deep Espresso Neutral
  static const Color textSecondary = Color(0xFF8D827A); // Warm Taupe
  static const Color textMuted = Color(0xFF9E9289);
  static const Color cardSurface = Colors.white; // Elevated card surface
  static const Color cardSurfaceWarm = Color(0xFFFFFDF9);
  static const Color inputBg = Color(0xFFFBF7F0);
  static const Color borderLight = Color(0x1F2D2622); // Subtle 12% border
  static const Color lightNavBg = Colors.white;

  // Compatibility aliases
  static const Color lightBg = background;
  static const Color lightPrimary = primaryAccent;
  static const Color primaryColor = primaryAccent;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color pastelGrowth = personalGrowth;
  static const Color pastelGrowthIcon = personalGrowthIcon;
  static const Color pastelPersonalGrowth = personalGrowth;
  static const Color pastelPersonalGrowthIcon = personalGrowthIcon;
  static const Color pastelCareer = career;
  static const Color pastelCareerIcon = careerIcon;
  static const Color pastelStudies = studies;
  static const Color pastelStudiesIcon = studiesIcon;
  static const Color pastelCalendar = calendar;
  static const Color pastelCalendarIcon = calendarIcon;
  static const Color pastelPriority = priority;
  static const Color pastelPriorityIcon = priorityIcon;
  static const Color pastelAnalytics = analytics;
  static const Color pastelAnalyticsIcon = analyticsIcon;

  // Matrix Quadrant Colors
  static const Color matrixDoFirst = Color(0xFF10B981); // Q1: Urgent & Important (Green)
  static const Color matrixSchedule = Color(0xFF3B82F6); // Q2: Not Urgent, Important (Blue)
  static const Color matrixDelegate = Color(0xFFF59E0B); // Q3: Urgent, Not Important (Amber)
  static const Color matrixEliminate = Color(0xFFEF4444); // Q4: Not Urgent, Not Important (Red)

  // ---------------------------------------------------------------------------
  // DARK MODE PALETTE (Deep Navy / Midnight Glow)
  // ---------------------------------------------------------------------------
  static const Color darkBg = Color(0xFF060B1E); // Deep Navy Canvas
  static const Color darkCardBg = Color(0xFF0D1B3E); // Midnight Blue Card
  static const Color darkCardBorder = Color(0x332A85FF); // Subtle 20% Blue Border
  static const Color darkPrimary = Color(0xFF2563EB); // Royal Electric Blue
  static const Color darkIconGlow = Color(0xFF2A85FF); // Glowing Cyan/Blue Icon
  static const Color darkIconBg = Color(0xFF132F5C); // Squircle Container
  static const Color darkTextPrimary = Colors.white; // Crisp White
  static const Color darkTextSecondary = Color(0xFF7E97B8); // Muted Steel Blue
  static const Color darkNavBg = Color(0xFF070D22); // Dark Navy Bar

  // ---------------------------------------------------------------------------
  // ELEVATION & SHADOWS
  // ---------------------------------------------------------------------------
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFFE87552).withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get darkCardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  // ---------------------------------------------------------------------------
  // THEME DATA DEFINITIONS
  // ---------------------------------------------------------------------------
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: background,
    primaryColor: primaryAccent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryAccent,
      brightness: Brightness.light,
      surface: background,
      primary: primaryAccent,
      secondary: primaryAccent,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardThemeData(
      color: cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          fontFamily: 'Poppins',
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: darkBg,
    primaryColor: darkPrimary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
      surface: darkBg,
      primary: darkPrimary,
      secondary: darkIconGlow,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardThemeData(
      color: darkCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: darkCardBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          fontFamily: 'Poppins',
        ),
      ),
    ),
  );
}
