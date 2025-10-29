import 'dart:async';
import 'package:flutter/foundation.dart';
import 'network_manager.dart';

/// A class that provides retry functionality for API calls
class RetryPolicy {
  static const int maxAttempts = 3;
  static const Duration initialDelay = Duration(milliseconds: 500);
  static const double backoffFactor = 2.0;

  /// Executes an API call with automatic retries on failure
  static Future<T> execute<T>({
    required Future<T> Function() apiCall,
    int maxAttempts = maxAttempts,
    Duration initialDelay = initialDelay,
    bool shouldRetry = true,
  }) async {
    int attempts = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      attempts++;
      try {
        // Check for network connectivity before making the call
        if (!await NetworkManager.instance.checkConnectivity()) {
          throw Exception('No internet connection');
        }

        return await apiCall();
      } catch (e) {
        if (!shouldRetry || attempts >= maxAttempts) {
          rethrow;
        }

        // Calculate exponential backoff delay
        final delay = currentDelay * (backoffFactor * (attempts - 1));
        debugPrint(
          'API call failed (attempt $attempts/$maxAttempts). '
          'Retrying in ${delay.inMilliseconds}ms',
        );

        // Wait before retrying
        await Future.delayed(delay);
        currentDelay = currentDelay * backoffFactor;
      }
    }
  }

  /// Determines if an error should trigger a retry
  static bool shouldRetry(dynamic error) {
    // Add specific error types that should trigger retries
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Network is unreachable')) {
      return true;
    }

    // Add specific HTTP status codes that should trigger retries
    if (error is Exception &&
        error.toString().contains(RegExp(r'(408|429|503|504)'))) {
      return true;
    }

    return false;
  }
}
