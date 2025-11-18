import 'package:flutter/material.dart';

/// Error Boundary Widget to catch and handle Flutter errors gracefully
/// Prevents red screen errors and shows user-friendly error messages
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, dynamic, StackTrace)? onError;
  final VoidCallback? onRetry;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.onRetry,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  dynamic error;
  StackTrace? stackTrace;

  @override
  void initState() {
    super.initState();
    // Add Flutter error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      if (!hasError) {
        setState(() {
          hasError = true;
          error = details.exception;
          stackTrace = details.stack;
        });
      }
      debugPrint('Error caught by ErrorBoundary: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };
  }

  @override
  void dispose() {
    // Clean up the error handler
    FlutterError.onError = FlutterError.presentError;
    super.dispose();
  }

  void _handleRetry() {
    setState(() {
      hasError = false;
      error = null;
      stackTrace = null;
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return widget.onError?.call(context, error, stackTrace!) ??
          _buildDefaultErrorWidget();
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'An unexpected error occurred. Please try again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.onRetry != null) ...[
                ElevatedButton(
                  onPressed: _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  child: const Text('Try Again'),
                ),
                const SizedBox(width: 12),
              ],
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.5),
                  ),
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Screen-level error boundary with navigation and refresh capabilities
class ScreenErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onNavigateHome;

  const ScreenErrorBoundary({
    super.key,
    required this.child,
    this.title,
    this.message,
    this.onRetry,
    this.onNavigateHome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          title ?? 'Error',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ErrorBoundary(
          onError: (context, error, stack) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message ?? 'An unexpected error occurred',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please check your connection and try again.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (onRetry != null) ...[
                          ElevatedButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        OutlinedButton.icon(
                          onPressed: onNavigateHome ?? () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
                          icon: const Icon(Icons.home),
                          label: const Text('Go Home'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          onRetry: onRetry,
          child: child,
        ),
      ),
    );
  }
}
