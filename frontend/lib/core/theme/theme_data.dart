import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'theme_extensions.dart';

/// Factory class to generate ThemeData for light theme only
class AppThemeData {
  /// Generates the light theme
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypographyExtended.displayLarge,
        displayMedium: AppTypographyExtended.displayMedium,
        headlineLarge: AppTypographyExtended.headlineLarge,
        headlineMedium: AppTypographyExtended.headlineMedium,
        headlineSmall: AppTypographyExtended.headlineSmall,
        titleLarge: AppTypographyExtended.titleLarge,
        titleMedium: AppTypographyExtended.titleMedium,
        titleSmall: AppTypographyExtended.titleSmall,
        bodyLarge: AppTypographyExtended.bodyLarge,
        bodyMedium: AppTypographyExtended.bodyMedium,
        bodySmall: AppTypographyExtended.bodySmall,
        labelLarge: AppTypographyExtended.labelLarge,
        labelMedium: AppTypographyExtended.labelMedium,
        labelSmall: AppTypographyExtended.labelSmall,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: TextStyle(color: AppColors.onSurface),
        hintStyle: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
        ),
      ),
      iconTheme: const IconThemeData(size: 24, color: AppColors.onSurface),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.onSurface),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(color: AppColors.onSurface),
        actionTextColor: AppColors.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        titleTextStyle: AppTypographyExtended.headlineSmall.copyWith(
          color: AppColors.onSurface,
        ),
        contentTextStyle: AppTypographyExtended.bodyMedium.copyWith(
          color: AppColors.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
      ),
    ).copyWith(extensions: <ThemeExtension<dynamic>>{CricketTheme.light});
  }
}
