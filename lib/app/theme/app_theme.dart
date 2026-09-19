import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Builds Flutter's ThemeData from the design tokens in app_colors.dart
/// and app_typography.dart. Role accent is applied per-screen (see
/// core/widgets/role_scaffold.dart) rather than baked in here, since
/// one MaterialApp serves five different role accents.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.statusInfo,
        onPrimary: Colors.white,
        secondary: AppColors.statusInfo,
        onSecondary: Colors.white,
        error: AppColors.statusCritical,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: textPrimary),
        titleLarge: AppTypography.title.copyWith(color: textPrimary),
        headlineSmall: AppTypography.heading.copyWith(color: textPrimary),
        bodyLarge: AppTypography.body.copyWith(color: textPrimary),
        bodyMedium: AppTypography.bodySmall.copyWith(color: textSecondary),
        bodySmall: AppTypography.caption.copyWith(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      useMaterial3: true,
    );
  }
}
