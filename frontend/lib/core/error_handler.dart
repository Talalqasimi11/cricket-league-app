import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Custom exception for API HTTP errors
class ApiHttpException implements Exception {
  final int statusCode;
  final String body;
  final String message;
  final http.Response? response;

  ApiHttpException({
    required this.statusCode,
    required this.body,
    required this.message,
    this.response,
  });

  @override
  String toString() {
    return 'ApiHttpException: $message (Status: $statusCode})';
  }

  /// Create ApiHttpException from http.Response
  factory ApiHttpException.fromResponse(http.Response response) {
    String message;
    String body = response.body;

    try {
      final responseBody = json.decode(response.body);
      message =
          responseBody['error'] ??
          responseBody['message'] ??
          _getDefaultMessage(response.statusCode);
    } catch (e) {
      message = _getDefaultMessage(response.statusCode);
    }

    return ApiHttpException(
      statusCode: response.statusCode,
      body: body,
      message: message,
      response: response,
    );
  }

  static String _getDefaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request data';
      case 401:
        return 'Authentication failed. Please check your credentials.';
      case 403:
        return 'You do not have permission to access this resource.';
      case 404:
        return 'Resource not found';
      case 422:
        return 'Validation error';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'An unexpected error occurred';
    }
  }
}

/// A class that handles API errors and provides user-friendly messages
class ErrorHandler {
  /// Parse error response from API and return a user-friendly message
  static String getErrorMessage(dynamic error) {
    if (error is ApiHttpException) {
      return error.message;
    } else if (error is http.Response) {
      try {
        final statusCode = error.statusCode;
        final responseBody = json.decode(error.body);

        // Handle different status codes
        switch (statusCode) {
          case 400:
            return responseBody['message'] ?? 'Invalid request data';
          case 401:
            return 'Authentication failed. Please check your credentials.';
          case 403:
            return 'You do not have permission to access this resource.';
          case 404:
            return responseBody['message'] ?? 'Resource not found';
          case 422:
            return responseBody['message'] ?? 'Validation error';
          case 500:
            return responseBody['message'] ?? 'Server error. Please try again later.';
          default:
            return responseBody['message'] ?? 'An unexpected error occurred';
        }
      } catch (e) {
        return 'Error processing response: ${error.reasonPhrase}';
      }
    } else if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Network is unreachable')) {
      return 'Network error. Please check your internet connection.';
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }

    return 'An unexpected error occurred';
  }

  /// Check if error is authentication-related and trigger logout if needed
  static bool handleAuthError(BuildContext context, dynamic error) {
    bool isAuthError = false;
    
    if (error is ApiHttpException) {
      if (error.statusCode == 401) {
        isAuthError = true;
      }
    } else if (error is http.Response) {
      if (error.statusCode == 401) {
        isAuthError = true;
      }
    }
    
    // If it's an auth error, trigger automatic logout
    if (isAuthError) {
      debugPrint('ErrorHandler: Detected 401 auth error, triggering logout');
      // Note: We'll initialize this in the main app
      // AuthErrorHandler.triggerAuthError(
      //   context, 
      //   AuthErrorEvent(reason: 'Token expired or invalid')
      // );
      return true;
    }
    
    return false;
  }

  /// Show error message as a snackbar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    // First check if it's an auth error and handle it
    if (handleAuthError(context, error)) {
      return; // Auth error already handled, don't show additional error
    }
    
    final message = getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show success message as a snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
