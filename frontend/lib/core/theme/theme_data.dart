import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'theme_extensions.dart';

/// Factory class to generate ThemeData objects for light and dark themes
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
        hintStyle: TextStyle(color: AppColors.onSurface.withOpacity(0.6)),
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
      iconTheme: const IconThemeData(
        size: 24,
        color: AppColors.onSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: AppColors.onSurface,
        ),
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
    ).copyWith(extensions: <ThemeExtension<dynamic>>{
      CricketTheme.light,
    });
  }

  /// Generates the dark theme
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: Color(0xFF1E1E1E),
        onSurface: Color(0xFFE0E0E0),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypographyExtended.displayLarge.copyWith(color: const Color(0xFFE0E0E0)),
        displayMedium: AppTypographyExtended.displayMedium.copyWith(color: const Color(0xFFE0E0E0)),
        headlineLarge: AppTypographyExtended.headlineLarge.copyWith(color: const Color(0xFFE0E0E0)),
        headlineMedium: AppTypographyExtended.headlineMedium.copyWith(color: const Color(0xFFE0E0E0)),
        headlineSmall: AppTypographyExtended.headlineSmall.copyWith(color: const Color(0xFFE0E0E0)),
        titleLarge: AppTypographyExtended.titleLarge.copyWith(color: const Color(0xFFE0E0E0)),
        titleMedium: AppTypographyExtended.titleMedium.copyWith(color: const Color(0xFFE0E0E0)),
        titleSmall: AppTypographyExtended.titleSmall.copyWith(color: const Color(0xFFE0E0E0)),
        bodyLarge: AppTypographyExtended.bodyLarge.copyWith(color: const Color(0xFFE0E0E0)),
        bodyMedium: AppTypographyExtended.bodyMedium.copyWith(color: const Color(0xFFE0E0E0)),
        bodySmall: AppTypographyExtended.bodySmall.copyWith(color: const Color(0xFFE0E0E0)),
        labelLarge: AppTypographyExtended.labelLarge.copyWith(color: const Color(0xFFE0E0E0)),
        labelMedium: AppTypographyExtended.labelMedium.copyWith(color: const Color(0xFFE0E0E0)),
        labelSmall: AppTypographyExtended.labelSmall.copyWith(color: const Color(0xFFE0E0E0)),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        color: const Color(0xFF2C2C2C),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: Color(0xFF555555)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: Color(0xFF555555)),
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
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
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
      iconTheme: const IconThemeData(
        size: 24,
        color: Color(0xFFE0E0E0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFE0E0E0),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Color(0xFFE0E0E0),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFFAAAAAA),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2C2C2C),
        contentTextStyle: TextStyle(color: Color(0xFFE0E0E0)),
        actionTextColor: AppColors.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        titleTextStyle: AppTypographyExtended.headlineSmall.copyWith(
          color: const Color(0xFFE0E0E0),
        ),
        contentTextStyle: AppTypographyExtended.bodyMedium.copyWith(
          color: const Color(0xFFE0E0E0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
      ),
    ).copyWith(extensions: <ThemeExtension<dynamic>>{
      CricketTheme.light, // Using light theme extension for now
    });
  }
}
