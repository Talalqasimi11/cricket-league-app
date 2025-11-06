import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme/theme_config.dart';

/// Utility class for handling API errors and showing user-friendly dialogs
class ErrorDialog {
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
            Icon(
              errorInfo.icon,
              color: errorInfo.iconColor,
              size: 24,
            ),
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
            Icon(
              errorInfo.icon,
              color: errorInfo.iconColor,
              size: 24,
            ),
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
            Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypographyExtended.headlineSmall,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTypographyExtended.bodyMedium,
        ),
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
        title: Text(
          title,
          style: AppTypographyExtended.headlineSmall,
        ),
        content: Text(
          message,
          style: AppTypographyExtended.bodyMedium,
        ),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: AppTypographyExtended.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a snackbar with error message
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: AppColors.onError),
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
      ),
    );
  }

  /// Shows a snackbar with success message
  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: AppColors.onPrimary),
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

  switch (statusCode) {
    case 400:
      return _ErrorInfo(
        title: 'Bad Request',
        message: 'The request was invalid. Please check your input and try again.',
        icon: Icons.warning,
        iconColor: AppColors.error,
      );

    case 401:
      return _ErrorInfo(
        title: 'Authentication Required',
        message: 'Please log in to continue.',
        icon: Icons.lock,
        iconColor: AppColors.error,
      );

    case 403:
      return _ErrorInfo(
        title: 'Access Denied',
        message: 'You don\'t have permission to perform this action.',
        icon: Icons.block,
        iconColor: AppColors.error,
      );

    case 404:
      return _ErrorInfo(
        title: 'Not Found',
        message: 'The requested resource was not found.',
        icon: Icons.search_off,
        iconColor: AppColors.error,
      );

    case 409:
      return _ErrorInfo(
        title: 'Conflict',
        message: 'This action conflicts with existing data.',
        icon: Icons.warning,
        iconColor: AppColors.error,
      );

    case 422:
      return _ErrorInfo(
        title: 'Validation Error',
        message: 'Please check your input data.',
        icon: Icons.error_outline,
        iconColor: AppColors.error,
      );

    case 429:
      return _ErrorInfo(
        title: 'Too Many Requests',
        message: 'Please wait a moment before trying again.',
        icon: Icons.timer,
        iconColor: AppColors.secondary,
      );

    case 500:
      return _ErrorInfo(
        title: 'Server Error',
        message: 'Something went wrong on our end. Please try again later.',
        icon: Icons.cloud_off,
        iconColor: AppColors.error,
      );

    case 502:
    case 503:
    case 504:
      return _ErrorInfo(
        title: 'Service Unavailable',
        message: 'The service is temporarily unavailable. Please try again later.',
        icon: Icons.cloud_off,
        iconColor: AppColors.error,
      );

    default:
      // Try to parse error message from response body
      try {
        final body = response.body;
        if (body.isNotEmpty) {
          // You can add JSON parsing here if your API returns structured errors
          return _ErrorInfo(
            title: 'Error',
            message: 'An error occurred: $body',
            icon: Icons.error,
            iconColor: AppColors.error,
          );
        }
      } catch (_) {
        // Ignore parsing errors
      }

      return _ErrorInfo(
        title: 'Connection Error',
        message: 'Unable to connect to the server. Please check your internet connection.',
        icon: Icons.wifi_off,
        iconColor: AppColors.error,
      );
  }
}

/// Parses generic exceptions and returns user-friendly error information
_ErrorInfo _parseGenericError(Object error) {
  if (error is FormatException) {
    return _ErrorInfo(
      title: 'Data Error',
      message: 'The received data was in an unexpected format.',
      icon: Icons.data_object,
      iconColor: AppColors.error,
    );
  }

  if (error.toString().contains('SocketException') ||
      error.toString().contains('Connection refused') ||
      error.toString().contains('Network is unreachable')) {
    return _ErrorInfo(
      title: 'Connection Error',
      message: 'Unable to connect to the server. Please check your internet connection.',
      icon: Icons.wifi_off,
      iconColor: AppColors.error,
    );
  }

  if (error.toString().contains('TimeoutException')) {
    return _ErrorInfo(
      title: 'Request Timeout',
      message: 'The request took too long to complete. Please try again.',
      icon: Icons.timer_off,
      iconColor: AppColors.secondary,
    );
  }

  return _ErrorInfo(
    title: 'Unexpected Error',
    message: 'An unexpected error occurred. Please try again.',
    icon: Icons.error,
    iconColor: AppColors.error,
  );
}
