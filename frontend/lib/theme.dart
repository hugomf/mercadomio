import 'package:flutter/material.dart';

/// Mercadomio Material 3 design tokens.
///
/// Palette and radii extracted from the Stitch storefront designs
/// (.stitch/designs/*.html). Typography approximates the Inter / Public Sans
/// pairing using the platform default family with matching weights.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF006B1B);

  static const Color primary = Color(0xFF006B1B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF268630);
  static const Color onPrimaryContainer = Color(0xFFF7FFF1);
  static const Color secondary = Color(0xFF446741);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFC2EABA);
  static const Color onSecondaryContainer = Color(0xFF486B45);
  static const Color tertiary = Color(0xFFA0335D);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFC04C76);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color surface = Color(0xFFF6FBF0);
  static const Color onSurface = Color(0xFF181D16);
  static const Color onSurfaceVariant = Color(0xFF3F4A3D);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F5EA);
  static const Color surfaceContainer = Color(0xFFEAF0E4);
  static const Color surfaceContainerHigh = Color(0xFFE5EADF);
  static const Color surfaceContainerHighest = Color(0xFFDFE4D9);
  static const Color outline = Color(0xFF6F7A6B);
  static const Color outlineVariant = Color(0xFFBFCAB9);
  static const Color inverseSurface = Color(0xFF2C322A);

  // Radii
  static const double radiusInput = 8;
  static const double radiusCard = 12;
  static const double radiusCardLarge = 16;

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: seed).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      outline: outline,
      outlineVariant: outlineVariant,
      inverseSurface: inverseSurface,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
      cardTheme: const CardThemeData(
        color: surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusCard)),
          side: BorderSide(color: outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceContainerHighest,
          disabledForegroundColor: onSurface.withValues(alpha: 0.38),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: outlineVariant),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: base.textTheme.bodyMedium?.copyWith(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: base.textTheme.bodyMedium?.copyWith(
          color: onSurfaceVariant.withValues(alpha: 0.7),
        ),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: primaryContainer,
        disabledColor: surfaceContainer,
        labelStyle: base.textTheme.labelMedium?.copyWith(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: base.textTheme.labelMedium?.copyWith(
          color: onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: onPrimaryContainer,
        surfaceTintColor: Colors.transparent,
        side: const BorderSide(color: outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusInput),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: inverseSurface,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: surfaceContainerLowest,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: outlineVariant,
        circularTrackColor: outlineVariant,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainer,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainer,
        indicatorColor: primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return base.textTheme.labelSmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            letterSpacing: 0.4,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: StadiumBorder(),
        elevation: 2,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        side: const BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : outline,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? onPrimary
              : surfaceContainerHighest,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : outlineVariant,
        ),
      ),
    );
  }
}