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

  // Material 3 surface container colors
  static const Color surfaceContainerHighest = Color(0xFFE7E0EC);

  // Outline colors
  static const Color outline = Color(0xFFCAC4D0);
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

// Deprecated: Use AppTypographyExtended instead

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

/// Elevation levels for consistent shadow system
class AppElevation {
  static const double level0 = 0.0;
  static const double level1 = 2.0;
  static const double level2 = 4.0;
  static const double level3 = 8.0;
  static const double level4 = 16.0;
  static const double level5 = 24.0;
}

/// Card-specific colors and gradients (theme-aware)
class AppCardColors {
  // Light theme colors
  static const Color lightCardSurface = Color(0xFFFFFFFF);
  static const Color lightCardSurfaceLight = Color(0xFFF5F5F5);
  static const Color lightCardBorder = Color(0xFFE0E0E0);

  // Dark theme colors
  static const Color darkCardSurface = Color(0xFF2C4A44);
  static const Color darkCardSurfaceLight = Color(0xFF3A5A52);
  static const Color darkCardBorder = Color(0xFF4A6A62);

  // Gradient colors (same for both themes)
  static const Color gradientStart = Color(0xFF20DF6C);
  static const Color gradientMiddle = Color(0xFF36e27b);
  static const Color gradientEnd = Color(0xFF4CAF50);

  // Status colors (same for both themes)
  static const Color liveStatus = Color(0xFFFF4444);
  static const Color finishedStatus = Color(0xFF4CAF50);
  static const Color upcomingStatus = Color(0xFFFF9800);

  // Helper methods to get theme-appropriate colors
  static Color cardSurface() => lightCardSurface;
  static Color cardSurfaceLight() => lightCardSurfaceLight;
  static Color cardBorder() => lightCardBorder;
}

/// Enhanced typography with better hierarchy
class AppTypographyExtended {
  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.0,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.8,
    height: 1.25,
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.35,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.0,
    height: 1.4,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.5,
  );

  // Body styles with improved readability
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
}
