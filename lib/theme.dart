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

// The same ten colors, once for the light theme and once for the dark theme.
// Screens read them with `context.palette.muted` instead of `AppColors.muted`,
// so they follow the theme the user picked (Light / Dark / System).
//
// The dark set keeps the warm, homey feel: a dark coffee-brown background
// instead of cold grey, and slightly lighter accents so they stay readable.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.terracotta,
    required this.sage,
    required this.mustard,
    required this.ink,
    required this.cream,
    required this.paper,
    required this.line,
    required this.getsBack,
    required this.owes,
    required this.muted,
    required this.button,
  });

  final Color terracotta;
  final Color sage;
  final Color mustard;
  final Color ink; // main text
  final Color cream; // page background
  final Color paper; // cards and input fields
  final Color line; // borders and dividers
  final Color getsBack; // money owed to you
  final Color owes; // money you owe
  final Color muted; // secondary text
  // Filled buttons and the FAB. In dark mode this is a deeper terracotta than the
  // accent, so big buttons do not glare on the dark background.
  final Color button;

  static const AppPalette light = AppPalette(
    terracotta: AppColors.terracotta,
    sage: AppColors.sage,
    mustard: AppColors.mustard,
    ink: AppColors.ink,
    cream: AppColors.cream,
    paper: AppColors.paper,
    line: AppColors.line,
    getsBack: AppColors.getsBack,
    owes: AppColors.owes,
    muted: AppColors.muted,
    button: AppColors.terracotta,
  );

  static const AppPalette dark = AppPalette(
    terracotta: Color(0xFFE07B60),
    sage: Color(0xFF86B89C),
    mustard: Color(0xFFF2C366),
    ink: Color(0xFFEDE6DA),
    cream: Color(0xFF1E1A17),
    paper: Color(0xFF2A2420),
    line: Color(0xFF3A322C),
    getsBack: Color(0xFF6FB58E),
    owes: Color(0xFFE0705F),
    muted: Color(0xFFA39A8E),
    button: Color(0xFFA9553F),
  );

  @override
  AppPalette copyWith({
    Color? terracotta,
    Color? sage,
    Color? mustard,
    Color? ink,
    Color? cream,
    Color? paper,
    Color? line,
    Color? getsBack,
    Color? owes,
    Color? muted,
    Color? button,
  }) {
    return AppPalette(
      terracotta: terracotta ?? this.terracotta,
      sage: sage ?? this.sage,
      mustard: mustard ?? this.mustard,
      ink: ink ?? this.ink,
      cream: cream ?? this.cream,
      paper: paper ?? this.paper,
      line: line ?? this.line,
      getsBack: getsBack ?? this.getsBack,
      owes: owes ?? this.owes,
      muted: muted ?? this.muted,
      button: button ?? this.button,
    );
  }

  // Used by Flutter to animate smoothly when the theme changes.
  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      terracotta: Color.lerp(terracotta, other.terracotta, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      mustard: Color.lerp(mustard, other.mustard, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      line: Color.lerp(line, other.line, t)!,
      getsBack: Color.lerp(getsBack, other.getsBack, t)!,
      owes: Color.lerp(owes, other.owes, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      button: Color.lerp(button, other.button, t)!,
    );
  }
}

// Short access from any widget: `context.palette.muted`.
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

ThemeData buildAppTheme() => _buildTheme(AppPalette.light, Brightness.light);

ThemeData buildDarkAppTheme() => _buildTheme(AppPalette.dark, Brightness.dark);

ThemeData _buildTheme(AppPalette p, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  var scheme = ColorScheme.fromSeed(
    seedColor: p.terracotta,
    brightness: brightness,
  ).copyWith(
    primary: p.terracotta,
    secondary: p.sage,
    tertiary: p.mustard,
    surface: p.paper,
    onSurface: p.ink,
    error: p.owes,
  );
  if (isDark) {
    // The seed's own dark surfaces are a cool grey. Bottom sheets, menus and
    // pickers use these, so warm them up to match the coffee-brown pages.
    scheme = scheme.copyWith(
      onPrimary: Colors.white,
      onSecondary: p.cream,
      onTertiary: p.cream,
      onError: Colors.white,
      onSurfaceVariant: p.muted,
      outline: p.muted,
      outlineVariant: p.line,
      surfaceContainerLowest: p.cream,
      surfaceContainerLow: p.paper,
      surfaceContainer: p.paper,
      surfaceContainerHigh: const Color(0xFF322B26),
      surfaceContainerHighest: p.line,
      inverseSurface: p.ink,
      onInverseSurface: p.cream,
    );
  }

  // Build the base first so the text theme can be adjusted below.
  final base = ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: 'Nunito',
    extensions: [p],
    scaffoldBackgroundColor: p.cream,
  );

  final text = base.textTheme.apply(
    bodyColor: p.ink,
    displayColor: p.ink,
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
    appBarTheme: AppBarTheme(
      backgroundColor: p.cream,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        color: p.ink,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.line),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.button,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
        // Only a minimum height, not full width: dialogs put buttons side by side, and a
        // button that demands infinite width there crashes. Screens stretch their main button.
        minimumSize: Size(64, 52),
        textStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: StadiumBorder(),
        side: BorderSide(color: p.terracotta),
        textStyle: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.button,
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
      fillColor: p.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.terracotta, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: p.mustard.withValues(alpha: 0.25),
      side: BorderSide.none,
      labelStyle: TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w700,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: p.terracotta,
      unselectedLabelColor: p.muted,
      indicatorColor: p.terracotta,
      labelStyle: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: p.line),
  );
}
