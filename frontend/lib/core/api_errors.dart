/// Base class for all API errors
class ApiError extends Error {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiError(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiError: $message (Status: $statusCode)';
}

/// Network-related errors (no connection, timeout, etc.)
class NetworkError extends ApiError {
  NetworkError(super.message);
}

/// Authentication errors (401, 403)
class AuthError extends ApiError {
  AuthError(super.message, {super.statusCode});
}

/// Client errors (400, 404, etc.)
class ClientError extends ApiError {
  ClientError(super.message, {super.statusCode, super.data});
}

/// Server errors (500+)
class ServerError extends ApiError {
  ServerError(super.message, {super.statusCode});
}

/// Validation errors (typically 422)
class ValidationError extends ClientError {
  final Map<String, List<String>>? errors;

  ValidationError(super.message, {this.errors, super.statusCode})
    : super(data: errors);

  @override
  String toString() {
    if (errors == null) return super.toString();
    final details = errors!.entries
        .map((e) => '${e.key}: ${e.value.join(', ')}')
        .join('\n');
    return '${super.toString()}\nValidation Errors:\n$details';
  }
}
