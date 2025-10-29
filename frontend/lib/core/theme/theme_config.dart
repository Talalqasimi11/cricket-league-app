import 'package:flutter/material.dart';

/// Core colors used throughout the app
class AppColors {
  static const Color primary = Color(0xFF20DF6C);
  static const Color secondary = Color(0xFF2962FF);
  static const Color error = Color(0xFFB00020);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);

  // Additional colors for common use
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFF44336);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color textSecondary = Color(0xFF757575);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color onDarkBackground = Color(0xFFFFFFFF);
  static const Color onDarkSurface = Color(0xFFFFFFFF);
}

/// Typography styles used throughout the app
class AppTypography {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body1 = TextStyle(fontSize: 16, letterSpacing: 0.15);

  static const TextStyle body2 = TextStyle(fontSize: 14, letterSpacing: 0.25);

  static const TextStyle button = TextStyle(
    fontSize: 14,
    letterSpacing: 0.75,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(fontSize: 12, letterSpacing: 0.4);
}

/// Spacing constants used throughout the app
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants used throughout the app
class AppBorderRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double round = 999.0;
}

/// Common animation durations
class AppAnimationDuration {
  static const Duration shortest = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);
}
