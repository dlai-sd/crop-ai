import 'package:flutter/material.dart';

/// Material 3 color scheme for DLAI Crop
class AppColors {
  // Primary (Green for agriculture theme)
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryDark = Color(0xFF1B5E20);

  // Secondary (Orange for energy/growth)
  static const Color secondary = Color(0xFFF57C00);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFE65100);

  // Tertiary (Blue for trust)
  static const Color tertiary = Color(0xFF1976D2);
  static const Color tertiaryLight = Color(0xFF64B5F6);
  static const Color tertiaryDark = Color(0xFF0D47A1);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color background = Color(0xFFFCFCFC);
  static const Color outline = Color(0xFFCACACB);
  static const Color outlineVariant = Color(0xFFCDC7C0);

  // Functional colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFB3261E);
  static const Color warning = Color(0xFFFFA500);
  static const Color info = Color(0xFF2196F3);

  // Text colors
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textTertiary = Color(0xFF79747E);
  static const Color textDisabled = Color(0xFFC5C7C1);

  // Backgrounds
  static const Color surfaceVariant = Color(0xFFE7E0EB);
  static const Color inversePrimary = Color(0xFFB1E6B4);
  static const Color inverseSurface = Color(0xFF313033);
}

/// Typography theme
/// Note: Using system default font (no custom fonts required for MVP)
/// Can add 'Aptos' font later by updating pubspec.yaml and adding font files
class AppTypography {
  // Use system default sans-serif font instead of custom 'Aptos'
  // Remove fontFamily to use system default for all TextStyles

  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    height: 1.12,
    letterSpacing: 0,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.15,
    letterSpacing: 0,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.22,
    letterSpacing: 0,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: 0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.29,
    letterSpacing: 0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.27,
    letterSpacing: 0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
  );
}

/// App theme
ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.secondaryLight,
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.tertiaryLight,
      onTertiaryContainer: AppColors.tertiaryDark,
      error: AppColors.error,
      onError: AppColors.white,
      background: AppColors.background,
      onBackground: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textPrimary),
      displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimary),
      displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textPrimary),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
      titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
      titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
      titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textSecondary),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
      labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      centerTitle: true,
      titleTextStyle: AppTypography.headlineSmall.copyWith(color: AppColors.white),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.outline),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
    ),
  );
}
