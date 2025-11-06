import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Custom theme extensions for Cricket League app
class CricketTheme extends ThemeExtension<CricketTheme> {
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color statusLive;
  final Color statusFinished;
  final Color statusUpcoming;
  final double cardElevation;
  final double borderRadius;
  final List<BoxShadow> cardShadow;

  const CricketTheme({
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.statusLive,
    required this.statusFinished,
    required this.statusUpcoming,
    required this.cardElevation,
    required this.borderRadius,
    required this.cardShadow,
  });

  // Light theme extension
  static const CricketTheme light = CricketTheme(
    cardGradientStart: Color(0xFF20DF6C),
    cardGradientEnd: Color(0xFF4CAF50),
    statusLive: Color(0xFFFF4444),
    statusFinished: Color(0xFF4CAF50),
    statusUpcoming: Color(0xFFFF9800),
    cardElevation: 2.0,
    borderRadius: 12.0,
    cardShadow: [
      BoxShadow(
        color: Color(0x11000000),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );



  @override
  CricketTheme copyWith({
    Color? cardGradientStart,
    Color? cardGradientEnd,
    Color? statusLive,
    Color? statusFinished,
    Color? statusUpcoming,
    double? cardElevation,
    double? borderRadius,
    List<BoxShadow>? cardShadow,
  }) {
    return CricketTheme(
      cardGradientStart: cardGradientStart ?? this.cardGradientStart,
      cardGradientEnd: cardGradientEnd ?? this.cardGradientEnd,
      statusLive: statusLive ?? this.statusLive,
      statusFinished: statusFinished ?? this.statusFinished,
      statusUpcoming: statusUpcoming ?? this.statusUpcoming,
      cardElevation: cardElevation ?? this.cardElevation,
      borderRadius: borderRadius ?? this.borderRadius,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  CricketTheme lerp(ThemeExtension<CricketTheme>? other, double t) {
    if (other is! CricketTheme) return this;

    return CricketTheme(
      cardGradientStart: Color.lerp(cardGradientStart, other.cardGradientStart, t)!,
      cardGradientEnd: Color.lerp(cardGradientEnd, other.cardGradientEnd, t)!,
      statusLive: Color.lerp(statusLive, other.statusLive, t)!,
      statusFinished: Color.lerp(statusFinished, other.statusFinished, t)!,
      statusUpcoming: Color.lerp(statusUpcoming, other.statusUpcoming, t)!,
      cardElevation: ui.lerpDouble(cardElevation, other.cardElevation, t)!,
      borderRadius: ui.lerpDouble(borderRadius, other.borderRadius, t)!,
      cardShadow: cardShadow, // Keep original shadow for now
    );
  }
}

/// Extension method to access CricketTheme from BuildContext
extension CricketThemeExtension on BuildContext {
  CricketTheme get cricketTheme {
    final theme = Theme.of(this);
    final cricketTheme = theme.extension<CricketTheme>();
    if (cricketTheme == null) {
      throw FlutterError('CricketTheme extension not found in theme. '
          'Make sure to add CricketTheme.light or CricketTheme.dark to your ThemeData.');
    }
    return cricketTheme;
  }
}

/// Theme validation utility
class ThemeValidator {
  static bool validateTheme(ThemeData theme) {
    final errors = <String>[];

    // Check required color scheme properties
    if (theme.colorScheme.primary == Colors.transparent) {
      errors.add('Primary color cannot be transparent');
    }

    if (theme.colorScheme.surface == Colors.transparent) {
      errors.add('Surface color cannot be transparent');
    }

    // Check text theme has required styles
    if (theme.textTheme.displayLarge == null) {
      errors.add('displayLarge text style is required');
    }

    if (theme.textTheme.bodyLarge == null) {
      errors.add('bodyLarge text style is required');
    }

    // Check for CricketTheme extension
    if (theme.extension<CricketTheme>() == null) {
      errors.add('CricketTheme extension is required');
    }

    if (errors.isNotEmpty) {
      debugPrint('Theme validation errors: ${errors.join(', ')}');
      return false;
    }

    return true;
  }

  static void logThemeInfo(ThemeData theme) {
    debugPrint('=== Theme Validation Report ===');
    debugPrint('Brightness: ${theme.brightness}');
    debugPrint('Primary Color: ${theme.colorScheme.primary}');
    debugPrint('Surface Color: ${theme.colorScheme.surface}');
    debugPrint('On Surface Color: ${theme.colorScheme.onSurface}');
    debugPrint('Has CricketTheme extension: ${theme.extension<CricketTheme>() != null}');
    debugPrint('Text theme styles count: ${theme.textTheme.toString().split(',').length}');
    debugPrint('===============================');
  }
}
