import 'package:flutter/material.dart';

/// A reusable widget for displaying navigation errors with recovery options.
/// 
/// This widget is used when route navigation fails due to missing or invalid arguments.
/// It provides a user-friendly error message and navigation options to recover.
/// 
/// Example usage in `onGenerateRoute`:
/// ```dart
/// if (args == null) {
///   return MaterialPageRoute(
///     builder: (_) => RouteErrorWidget(
///       error: 'Missing required arguments',
///       routeName: settings.name,
///     ),
///   );
/// }
/// ```
class RouteErrorWidget extends StatelessWidget {
  /// The error message to display
  final String error;
  
  /// The name of the route that failed (optional)
  final String? routeName;
  
  /// Custom title for the error screen
  final String? title;
  
  /// Whether to show the "Go Home" button (default: true)
  final bool showHomeButton;
  
  /// Custom icon to display (default: Icons.error_outline)
  final IconData? icon;
  
  /// Custom color for the icon and buttons (default: theme error color)
  final Color? iconColor;

  const RouteErrorWidget({
    super.key,
    required this.error,
    this.routeName,
    this.title,
    this.showHomeButton = true,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = iconColor ?? theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Navigation Error'),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Icon(
                icon ?? Icons.error_outline,
                size: 80,
                color: errorColor,
              ),
              
              const SizedBox(height: 24),
              
              // Error title
              Text(
                title ?? 'Oops! Something went wrong',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Error message
              Text(
                error,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              // Route name (if provided)
              if (routeName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Route: $routeName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back button (only if can pop)
                  if (Navigator.of(context).canPop()) ...[
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    
                    if (showHomeButton) const SizedBox(width: 16),
                  ],
                  
                  // Home button
                  if (showHomeButton)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to home and clear all previous routes
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Go Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Help text
              Text(
                'If this problem persists, please contact support',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact version of RouteErrorWidget for inline errors
class InlineRouteError extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const InlineRouteError({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
