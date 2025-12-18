import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme/theme_config.dart';

/// Utility class for handling API errors and showing user-friendly dialogs
class ErrorDialog {
  /// Shows a simple error message dialog (convenience method)
  static Future<void> show(
    BuildContext context,
    String message, {
    String title = 'Error',
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: AppTypographyExtended.headlineSmall),
            ),
          ],
        ),
        content: Text(message, style: AppTypographyExtended.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows an error dialog with appropriate message based on HTTP response
  static Future<void> showApiError(
    BuildContext context, {
    required http.Response response,
    String? customTitle,
    String? customMessage,
    VoidCallback? onRetry,
    bool showRetryButton = true,
  }) async {
    final errorInfo = _parseApiError(response);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Row(
          children: [
            Icon(errorInfo.icon, color: errorInfo.iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                customTitle ?? errorInfo.title,
                style: AppTypographyExtended.headlineSmall,
              ),
            ),
          ],
        ),
        content: Text(
          customMessage ?? errorInfo.message,
          style: AppTypographyExtended.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (showRetryButton && onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Shows a generic error dialog for exceptions
  static Future<void> showGenericError(
    BuildContext context, {
    required Object error,
    String? customTitle,
    String? customMessage,
    VoidCallback? onRetry,
    bool showRetryButton = false,
  }) async {
    final errorInfo = _parseGenericError(error);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Row(
          children: [
            Icon(errorInfo.icon, color: errorInfo.iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                customTitle ?? errorInfo.title,
                style: AppTypographyExtended.headlineSmall,
              ),
            ),
          ],
        ),
        content: Text(
          customMessage ?? errorInfo.message,
          style: AppTypographyExtended.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (showRetryButton && onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Shows a success dialog
  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Success',
    VoidCallback? onOk,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: AppTypographyExtended.headlineSmall),
            ),
          ],
        ),
        content: Text(message, style: AppTypographyExtended.bodyMedium),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOk?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Text(title, style: AppTypographyExtended.headlineSmall),
        content: Text(message, style: AppTypographyExtended.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppColors.error,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Shows a loading dialog
  static Future<void> showLoading(
    BuildContext context, {
    required String message,
    bool barrierDismissible = false,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => PopScope(
        canPop: barrierDismissible,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          ),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(message, style: AppTypographyExtended.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hides the loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Shows a snackbar with error message
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.onError, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.onError),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        action: action,
      ),
    );
  }

  /// Shows a snackbar with success message
  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        action: action,
      ),
    );
  }

  /// Shows a snackbar with info message
  static void showInfoSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        action: action,
      ),
    );
  }

  /// Shows a snackbar with warning message
  static void showWarningSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.black87,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        action: action,
      ),
    );
  }

  /// Shows a bottom sheet with error details
  static Future<void> showErrorBottomSheet(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypographyExtended.headlineMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(message, style: AppTypographyExtended.bodyLarge),
            if (details != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Details:',
                      style: AppTypographyExtended.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(details, style: AppTypographyExtended.bodySmall),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
            // Add padding for bottom safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// Internal helper class for error information
class _ErrorInfo {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const _ErrorInfo({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
  });
}

/// Parses API error responses and returns user-friendly error information
_ErrorInfo _parseApiError(http.Response response) {
  final statusCode = response.statusCode;

  // Try to extract custom error message from response body
  String? customMessage;
  try {
    final body = response.body;
    if (body.isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        customMessage =
            decoded['error']?.toString() ?? decoded['message']?.toString();
      }
    }
  } catch (_) {
    // Ignore parsing errors
  }

  switch (statusCode) {
    case 400:
      return _ErrorInfo(
        title: 'Bad Request',
        message:
            customMessage ??
            'The request was invalid. Please check your input and try again.',
        icon: Icons.warning,
        iconColor: AppColors.error,
      );

    case 401:
      return _ErrorInfo(
        title: 'Authentication Required',
        message: customMessage ?? 'Please log in to continue.',
        icon: Icons.lock,
        iconColor: AppColors.error,
      );

    case 403:
      return _ErrorInfo(
        title: 'Access Denied',
        message:
            customMessage ??
            'You don\'t have permission to perform this action.',
        icon: Icons.block,
        iconColor: AppColors.error,
      );

    case 404:
      return _ErrorInfo(
        title: 'Not Found',
        message: customMessage ?? 'The requested resource was not found.',
        icon: Icons.search_off,
        iconColor: AppColors.error,
      );

    case 409:
      return _ErrorInfo(
        title: 'Conflict',
        message: customMessage ?? 'This action conflicts with existing data.',
        icon: Icons.warning,
        iconColor: AppColors.error,
      );

    case 422:
      return _ErrorInfo(
        title: 'Validation Error',
        message: customMessage ?? 'Please check your input data.',
        icon: Icons.error_outline,
        iconColor: AppColors.error,
      );

    case 429:
      return _ErrorInfo(
        title: 'Too Many Requests',
        message: customMessage ?? 'Please wait a moment before trying again.',
        icon: Icons.timer,
        iconColor: AppColors.secondary,
      );

    case 500:
      return _ErrorInfo(
        title: 'Server Error',
        message:
            customMessage ??
            'Something went wrong on our end. Please try again later.',
        icon: Icons.cloud_off,
        iconColor: AppColors.error,
      );

    case 502:
    case 503:
    case 504:
      return _ErrorInfo(
        title: 'Service Unavailable',
        message:
            customMessage ??
            'The service is temporarily unavailable. Please try again later.',
        icon: Icons.cloud_off,
        iconColor: AppColors.error,
      );

    default:
      return _ErrorInfo(
        title: 'Connection Error',
        message:
            customMessage ??
            'Unable to connect to the server. Please check your internet connection.',
        icon: Icons.wifi_off,
        iconColor: AppColors.error,
      );
  }
}

/// Parses generic exceptions and returns user-friendly error information
_ErrorInfo _parseGenericError(Object error) {
  if (error is FormatException) {
    return const _ErrorInfo(
      title: 'Data Error',
      message: 'The received data was in an unexpected format.',
      icon: Icons.data_object,
      iconColor: AppColors.error,
    );
  }

  final errorString = error.toString();

  if (errorString.contains('SocketException') ||
      errorString.contains('Connection refused') ||
      errorString.contains('Network is unreachable') ||
      errorString.contains('Failed host lookup')) {
    return const _ErrorInfo(
      title: 'Connection Error',
      message:
          'Unable to connect to the server. Please check your internet connection.',
      icon: Icons.wifi_off,
      iconColor: AppColors.error,
    );
  }

  if (errorString.contains('TimeoutException') ||
      errorString.contains('timed out')) {
    return const _ErrorInfo(
      title: 'Request Timeout',
      message: 'The request took too long to complete. Please try again.',
      icon: Icons.timer_off,
      iconColor: AppColors.secondary,
    );
  }

  if (errorString.contains('HandshakeException') ||
      errorString.contains('CERTIFICATE_VERIFY_FAILED')) {
    return const _ErrorInfo(
      title: 'Security Error',
      message: 'Unable to establish a secure connection.',
      icon: Icons.security,
      iconColor: AppColors.error,
    );
  }

  return const _ErrorInfo(
    title: 'Unexpected Error',
    message: 'An unexpected error occurred. Please try again.',
    icon: Icons.error,
    iconColor: AppColors.error,
  );
}
