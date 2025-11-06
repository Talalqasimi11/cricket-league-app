import 'package:flutter/material.dart';

/// Custom icon library for the Cricket League app
/// Provides consistent icon usage throughout the application
class AppIcons {
  // Cricket-themed icons (using SVG strings for custom icons)
  static const String cricketBall = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="#8B4513" stroke="#654321" stroke-width="2"/>
  <path d="M8 8L16 16" stroke="white" stroke-width="2" stroke-linecap="round"/>
  <path d="M16 8L8 16" stroke="white" stroke-width="2" stroke-linecap="round"/>
  <circle cx="12" cy="12" r="2" fill="white"/>
</svg>
''';

  static const String cricketBat = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="8" width="4" height="12" fill="#8B4513" stroke="#654321" stroke-width="1"/>
  <path d="M2 20L6 20" stroke="#654321" stroke-width="2" stroke-linecap="round"/>
  <path d="M7 8L18 2" stroke="#8B4513" stroke-width="3" stroke-linecap="round"/>
  <path d="M18 2L22 6" stroke="#8B4513" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  static const String wicket = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="2" y="4" width="20" height="2" fill="#8B4513"/>
  <rect x="2" y="8" width="20" height="2" fill="#8B4513"/>
  <rect x="2" y="12" width="20" height="2" fill="#8B4513"/>
  <line x1="6" y1="2" x2="6" y2="16" stroke="#654321" stroke-width="2"/>
  <line x1="12" y1="2" x2="12" y2="16" stroke="#654321" stroke-width="2"/>
  <line x1="18" y1="2" x2="18" y2="16" stroke="#654321" stroke-width="2"/>
</svg>
''';

  static const String trophy = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 9L8 21H16L18 9H6Z" fill="#FFD700" stroke="#B8860B" stroke-width="2"/>
  <rect x="8" y="3" width="8" height="6" fill="#FFD700" stroke="#B8860B" stroke-width="2"/>
  <circle cx="12" cy="6" r="1" fill="#B8860B"/>
  <rect x="9" y="1" width="6" height="2" fill="#FFD700" stroke="#B8860B" stroke-width="1"/>
</svg>
''';

  // Standard icon sizes
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// Cricket ball icon (placeholder - using Material icon for now)
  static Widget cricketBallIcon({
    double size = md,
    Color? color,
  }) => themedIcon(Icons.sports_baseball, size: size, color: color, semanticLabel: 'Cricket Ball');

  /// Cricket bat icon (placeholder - using Material icon for now)
  static Widget cricketBatIcon({
    double size = md,
    Color? color,
  }) => themedIcon(Icons.sports_cricket, size: size, color: color, semanticLabel: 'Cricket Bat');

  /// Wicket icon (placeholder - using Material icon for now)
  static Widget wicketIcon({
    double size = md,
    Color? color,
  }) => themedIcon(Icons.sports_soccer, size: size, color: color, semanticLabel: 'Wicket');

  /// Trophy icon (placeholder - using Material icon for now)
  static Widget trophyIcon({
    double size = md,
    Color? color,
  }) => themedIcon(Icons.emoji_events, size: size, color: color, semanticLabel: 'Trophy');

  /// Enhanced Material Icons with consistent theming
  static Icon themedIcon(IconData icon, {
    double size = md,
    Color? color,
    String? semanticLabel,
  }) {
    return Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }

  /// Home icon
  static Icon homeIcon({double size = md, Color? color}) =>
      themedIcon(Icons.home, size: size, color: color, semanticLabel: 'Home');

  /// Search icon
  static Icon searchIcon({double size = md, Color? color}) =>
      themedIcon(Icons.search, size: size, color: color, semanticLabel: 'Search');

  /// Person/User icon
  static Icon personIcon({double size = md, Color? color}) =>
      themedIcon(Icons.person, size: size, color: color, semanticLabel: 'User');

  /// Settings icon
  static Icon settingsIcon({double size = md, Color? color}) =>
      themedIcon(Icons.settings, size: size, color: color, semanticLabel: 'Settings');

  /// Notifications icon
  static Icon notificationsIcon({double size = md, Color? color}) =>
      themedIcon(Icons.notifications, size: size, color: color, semanticLabel: 'Notifications');

  /// Menu icon
  static Icon menuIcon({double size = md, Color? color}) =>
      themedIcon(Icons.menu, size: size, color: color, semanticLabel: 'Menu');

  /// Close icon
  static Icon closeIcon({double size = md, Color? color}) =>
      themedIcon(Icons.close, size: size, color: color, semanticLabel: 'Close');

  /// Add/Plus icon
  static Icon addIcon({double size = md, Color? color}) =>
      themedIcon(Icons.add, size: size, color: color, semanticLabel: 'Add');

  /// Edit icon
  static Icon editIcon({double size = md, Color? color}) =>
      themedIcon(Icons.edit, size: size, color: color, semanticLabel: 'Edit');

  /// Delete icon
  static Icon deleteIcon({double size = md, Color? color}) =>
      themedIcon(Icons.delete, size: size, color: color, semanticLabel: 'Delete');

  /// Refresh icon
  static Icon refreshIcon({double size = md, Color? color}) =>
      themedIcon(Icons.refresh, size: size, color: color, semanticLabel: 'Refresh');

  /// Arrow back icon
  static Icon arrowBackIcon({double size = md, Color? color}) =>
      themedIcon(Icons.arrow_back, size: size, color: color, semanticLabel: 'Back');

  /// Arrow forward icon
  static Icon arrowForwardIcon({double size = md, Color? color}) =>
      themedIcon(Icons.arrow_forward, size: size, color: color, semanticLabel: 'Forward');

  /// Check icon
  static Icon checkIcon({double size = md, Color? color}) =>
      themedIcon(Icons.check, size: size, color: color, semanticLabel: 'Check');

  /// Error icon
  static Icon errorIcon({double size = md, Color? color}) =>
      themedIcon(Icons.error, size: size, color: color, semanticLabel: 'Error');

  /// Warning icon
  static Icon warningIcon({double size = md, Color? color}) =>
      themedIcon(Icons.warning, size: size, color: color, semanticLabel: 'Warning');

  /// Info icon
  static Icon infoIcon({double size = md, Color? color}) =>
      themedIcon(Icons.info, size: size, color: color, semanticLabel: 'Info');

  /// Sports cricket icon
  static Icon cricketIcon({double size = md, Color? color}) =>
      themedIcon(Icons.sports_cricket, size: size, color: color, semanticLabel: 'Cricket');

  /// Emoji events (trophy alternative)
  static Icon trophyAltIcon({double size = md, Color? color}) =>
      themedIcon(Icons.emoji_events, size: size, color: color, semanticLabel: 'Trophy');

  /// Shield icon
  static Icon shieldIcon({double size = md, Color? color}) =>
      themedIcon(Icons.shield, size: size, color: color, semanticLabel: 'Shield');

  /// Group icon
  static Icon groupIcon({double size = md, Color? color}) =>
      themedIcon(Icons.group, size: size, color: color, semanticLabel: 'Group');

  /// Sports icon
  static Icon sportsIcon({double size = md, Color? color}) =>
      themedIcon(Icons.sports, size: size, color: color, semanticLabel: 'Sports');

  /// Live TV icon
  static Icon liveTvIcon({double size = md, Color? color}) =>
      themedIcon(Icons.live_tv, size: size, color: color, semanticLabel: 'Live');

  /// Scoreboard icon
  static Icon scoreboardIcon({double size = md, Color? color}) =>
      themedIcon(Icons.scoreboard, size: size, color: color, semanticLabel: 'Scoreboard');

  /// Calendar icon
  static Icon calendarIcon({double size = md, Color? color}) =>
      themedIcon(Icons.calendar_today, size: size, color: color, semanticLabel: 'Calendar');

  /// Location/Map pin icon
  static Icon locationIcon({double size = md, Color? color}) =>
      themedIcon(Icons.location_on, size: size, color: color, semanticLabel: 'Location');

  /// Visibility icon
  static Icon visibilityIcon({double size = md, Color? color}) =>
      themedIcon(Icons.visibility, size: size, color: color, semanticLabel: 'Visible');

  /// Visibility off icon
  static Icon visibilityOffIcon({double size = md, Color? color}) =>
      themedIcon(Icons.visibility_off, size: size, color: color, semanticLabel: 'Hidden');
}
