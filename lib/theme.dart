import 'package:flutter/material.dart';

// The app is meant to feel warm and friendly, like a cozy shared home rather
// than a bank. So the palette uses soft, earthy colors, rounded shapes and a
// rounded typeface. Brick red and green are kept for money only, so "you owe"
// and "you are owed" always stand out, even though the rest of the app is gentle.

class AppColors {
  AppColors._();

  // Brand color, used for buttons, the FAB and focus rings.
  static const Color terracotta = Color(0xFFD96C4F);
  // Secondary accent, a calm green-grey.
  static const Color sage = Color(0xFF6FA287);
  // Tertiary accent, a warm yellow used for chips and highlights.
  static const Color mustard = Color(0xFFF2B84B);
  // Main text color: a soft navy instead of pure black.
  static const Color ink = Color(0xFF3D405B);
  // Page background: a warm off-white.
  static const Color cream = Color(0xFFFAF3E6);
  // Cards and input fields: a slightly lighter, paper-like white.
  static const Color paper = Color(0xFFFFFCF7);
  // Subtle borders and dividers.
  static const Color line = Color(0xFFEDE4D8);
  // Money owed TO you (green).
  static const Color getsBack = Color(0xFF4E8A6C);
  // Money you owe (brick red).
  static const Color owes = Color(0xFFB5443B);
  // Secondary text, hints and unselected tabs.
  static const Color muted = Color(0xFF8A8C9E);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.terracotta).copyWith(
    primary: AppColors.terracotta,
    secondary: AppColors.sage,
    tertiary: AppColors.mustard,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
    error: AppColors.owes,
  );

  // Build the base first so the text theme can be adjusted below.
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: AppColors.cream,
  );

  final text = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );

  return base.copyWith(
    textTheme: text.copyWith(
      displayLarge: text.displayLarge?.copyWith(fontWeight: FontWeight.w800),
      displayMedium: text.displayMedium?.copyWith(fontWeight: FontWeight.w800),
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        // Only a minimum height, not full width: dialogs put buttons side by side, and a
        // button that demands infinite width there crashes. Screens stretch their main button.
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.terracotta),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.terracotta,
      foregroundColor: Colors.white,
      shape: StadiumBorder(),
      elevation: 2,
      extendedTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.mustard.withValues(alpha: 0.25),
      side: BorderSide.none,
      labelStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w700,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.terracotta,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.terracotta,
      labelStyle: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line),
  );
}
