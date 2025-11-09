import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, debugPrint, kIsWeb, kDebugMode;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'error_handler.dart';

class _QueuedRequest {
  final String method;
  final String path;
  final Object? body;
  final Map<String, String>? headers;
  final Completer completer;
  final DateTime timestamp;

  _QueuedRequest({
    required this.method,
    required this.path,
    this.body,
    this.headers,
    required this.completer,
  }) : timestamp = DateTime.now();
}

class _CacheEntry {
  final http.Response response;
  final DateTime expiresAt;

  _CacheEntry({required this.response, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class ApiClient {
  ApiClient._() : _client = http.Client();
  static final ApiClient instance = ApiClient._();

  // Cached base URL for synchronous access
  String? _cachedBaseUrl;
  bool _isInitialized = false;

  // Private http.Client field to prevent resource leaks
  late final http.Client _client;

  // Platform-aware base URL detection
  static String get baseUrl {
    return instance._cachedBaseUrl ?? instance.getPlatformDefaultUrl();
  }

  // Initialize the cached base URL at app startup (now non-blocking)
  Future<void> init() async {
    if (_isInitialized) return;

    // Asynchronous base URL setup - don't await this
    getConfiguredBaseUrl()
        .then((url) {
          _cachedBaseUrl = url;
          debugPrint('[ApiClient] Base URL configured: $url');
        })
        .catchError((error) {
          debugPrint('[ApiClient] Error configuring base URL: $error');
          // Fallback to platform default on error
          _cachedBaseUrl = getPlatformDefaultUrl();
        });

    // Initialize connectivity listener synchronously
    _initializeConnectivityListener();

    _isInitialized = true;
    debugPrint('[ApiClient] Init completed (isInitialized=true)');

    // Start background health check
    _checkServerHealth();
  }

  void _initializeConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      dynamic result,
    ) {
      final wasOnline = _isOnline;

      List<ConnectivityResult> results = [];
      if (result is List<ConnectivityResult>) {
        results = result;
      } else if (result is ConnectivityResult) {
        results = [result];
      }

      // Check if any result indicates a connection
      _isOnline = results.any((res) => res != ConnectivityResult.none);

      debugPrint('Connectivity changed: $_isOnline (results: $results)');

      // Process queued requests when connection is restored
      if (!wasOnline && _isOnline) {
        _processQueuedRequests();
      }
    });
  }

  bool get isOnline => _isOnline;

  String getPlatformDefaultUrl() {
    debugPrint(
      '[Developer] Detecting platform default URL for $defaultTargetPlatform',
    );

    // For mobile platforms
    if (defaultTargetPlatform == TargetPlatform.android) {
      const url = 'http://10.0.2.2:5000'; // Android emulator
      debugPrint('[Developer] Android detected, using emulator URL: $url');
      return url;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Check if physical device (this is synchronous but may not be perfect)
      // Physical iOS devices cannot connect to localhost, need IP
      const url =
          'http://localhost:5000'; // iOS simulator or physical with manual config
      debugPrint(
        '[Developer] iOS detected, using localhost URL: $url (Note: Physical devices may need custom URL in developer settings)',
      );
      return url;
    } else {
      const url = 'http://localhost:5000';
      debugPrint(
        '[Developer] Other platform detected, using localhost URL: $url',
      );
      return url;
    }
  }

  // New methods for custom URL configuration
  Future<void> setCustomBaseUrl(String url) async {
    // Normalize URL by trimming trailing slash
    final normalizedUrl = _normalizeUrl(url);
    await _writeToStorage('custom_api_url', normalizedUrl);
    // Update cached URL
    _cachedBaseUrl = normalizedUrl;
  }

  Future<void> clearCustomBaseUrl() async {
    await _deleteFromStorage('custom_api_url');
    // Update cached URL to platform default
    _cachedBaseUrl = getPlatformDefaultUrl();
  }

  Future<String> getConfiguredBaseUrl() async {
    // First priority: Check for API_BASE_URL environment variable
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return _normalizeUrl(envUrl);
    }

    // Second priority: Check for custom URL in storage
    final customUrl = await _readFromStorage('custom_api_url');
    if (customUrl != null && customUrl.isNotEmpty) {
      return _normalizeUrl(customUrl);
    }

    // Third priority: Platform default
    return getPlatformDefaultUrl();
  }

  // Helper method to get the actual base URL for API calls
  Future<String> _getBaseUrl() async {
    // Use cached URL if available, otherwise get configured URL
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }
    return await getConfiguredBaseUrl();
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Mobile storage abstraction
  Future<void> _writeToStorage(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> _readFromStorage(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> _deleteFromStorage(String key) async {
    await _storage.delete(key: key);
  }

  // URL normalization helper
  String _normalizeUrl(String url) {
    return url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  // URL joining helper
  String _joinUrl(String base, String path) {
    final normalizedBase = _normalizeUrl(base);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }

  Future<String?> get token async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> get refreshToken async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  Future<void> clearRefreshToken() async {
    await _storage.delete(key: 'refresh_token');
  }

  // Background server health check
  Future<void> _checkServerHealth() async {
    try {
      debugPrint('[ApiClient] Starting background health check');
      final response = await get(
        '/health',
        timeout: const Duration(seconds: 3),
      );
      if (response.statusCode == 200) {
        debugPrint('[ApiClient] Server health check PASSED');
      } else {
        debugPrint(
          '[ApiClient] Server health check FAILED: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[ApiClient] Server health check ERROR: $e');
      // Optionally queue a retry or just log
    }
  }

  // Dispose method to close the http.Client and prevent resource leaks
  void dispose() {
    debugPrint('[ApiClient] Disposing resources...');
    try {
      _client.close();
      debugPrint('[ApiClient] HTTP client closed');
    } catch (e) {
      debugPrint('[ApiClient] Error closing HTTP client: $e');
    }

    try {
      _connectivitySubscription?.cancel();
      debugPrint('[ApiClient] Connectivity subscription cancelled');
    } catch (e) {
      debugPrint('[ApiClient] Error cancelling connectivity subscription: $e');
    }

    _requestQueue.clear();
    _cache.clear();
    debugPrint('[ApiClient] Disposal complete');
  }

  // Request queuing for offline mode
  final List<_QueuedRequest> _requestQueue = [];
  final Map<String, _CacheEntry> _cache = {};
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  static const Duration _defaultTimeout = Duration(seconds: 5);
  static const _maxRetries = 3;
  static const _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    Exception? lastError;

    for (var i = 0; i < _maxRetries; i++) {
      try {
        return await fn();
      } on TimeoutException catch (e) {
        lastError = e;
        if (i < _maxRetries - 1) {
          await Future.delayed(_retryDelays[i]);
        }
      } on http.ClientException catch (e) {
        lastError = e;
        if (i < _maxRetries - 1) {
          await Future.delayed(_retryDelays[i]);
        }
      }
    }

    throw lastError ?? Exception('Request failed after $_maxRetries retries');
  }

  void _logRequest(
    String method,
    String path,
    Map<String, String> headers, [
    Object? body,
  ]) {
    if (kDebugMode) {
      debugPrint('[Request] $method $path');
      debugPrint('  Headers: ${headers.keys.join(", ")}');
      if (body != null) {
        final bodyStr = body.toString();
        debugPrint(
          '  Body: ${bodyStr.substring(0, bodyStr.length > 200 ? 200 : bodyStr.length)}...',
        );
      }
    }
  }

  void _logResponse(String method, String path, http.Response response) {
    if (kDebugMode) {
      debugPrint('[Response] $method $path - ${response.statusCode}');
      if (response.statusCode >= 400) {
        final respBody = response.body;
        debugPrint(
          '  Error: ${respBody.substring(0, respBody.length > 200 ? 200 : respBody.length)}...',
        );
      }
    }
  }

  void _logError(String method, String path, dynamic error) {
    debugPrint('[Error] $method $path - $error');
  }

  Future<void> _processQueuedRequests() async {
    final queue = List.from(_requestQueue);
    _requestQueue.clear();

    for (final request in queue) {
      try {
        debugPrint(
          'Processing queued ${request.method} request to ${request.path}',
        );

        late http.Response response;
        switch (request.method) {
          case 'GET':
            response = await get(request.path, headers: request.headers);
            break;
          case 'POST':
            response = await post(
              request.path,
              body: request.body,
              headers: request.headers,
            );
            break;
          case 'PUT':
            response = await put(
              request.path,
              body: request.body,
              headers: request.headers,
            );
            break;
          case 'DELETE':
            response = await delete(
              request.path,
              body: request.body,
              headers: request.headers,
            );
            break;
        }

        if (!request.completer.isCompleted) {
          request.completer.complete(response);
        }
      } catch (e) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
        }
      }
    }
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Duration? cacheDuration,
    Duration timeout = _defaultTimeout,
    bool forceRefresh = false,
  }) async {
    return _withRetry(() async {
      final authHeaders = await _authHeaders(headers);
      _logRequest('GET', path, authHeaders);

      final baseUrl = await _getBaseUrl();
      final url = _joinUrl(baseUrl, path);

      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedResponse = _getCachedResponse(path, authHeaders, headers);
        if (cachedResponse != null) {
          debugPrint('[Cache] GET $path - returning cached response');
          return cachedResponse;
        }
      }

      // If offline, return cached response or queue request
      if (!_isOnline) {
        final cachedResponse = _getCachedResponse(path, authHeaders, headers);
        if (cachedResponse != null) {
          debugPrint('[Offline] GET $path - returning cached response');
          return cachedResponse;
        }

        // Queue the request for later processing
        final completer = Completer<http.Response>();
        _requestQueue.add(
          _QueuedRequest(
            method: 'GET',
            path: path,
            headers: headers,
            completer: completer,
          ),
        );
        debugPrint('[Offline] GET $path - queued for processing');
        return await completer.future;
      }

      final completer = Completer<http.Response>();
      Timer? timeoutTimer;

      try {
        // Set timeout
        timeoutTimer = Timer(timeout, () {
          if (!completer.isCompleted) {
            completer.completeError(
              TimeoutException('Request timed out', timeout),
            );
          }
        });

        final response = await _withRefreshRetry(() async {
          final resp = await _client.get(Uri.parse(url), headers: authHeaders);
          _logResponse('GET', path, resp);

          if (resp.statusCode >= 400) {
            throw ApiHttpException.fromResponse(resp);
          }

          // Cache successful responses
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            _cacheResponse(
              path,
              authHeaders,
              headers,
              resp,
              cacheDuration ?? _defaultCacheDuration,
            );
          }

          return resp;
        });

        if (!completer.isCompleted) {
          completer.complete(response);
        }

        return response;
      } catch (error) {
        _logError('GET', path, error);
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        rethrow;
      } finally {
        timeoutTimer?.cancel();
      }
    });
  }

  // Helper methods for caching
  String _getCacheKey(
    String path,
    Map<String, String> authHeaders,
    Map<String, String>? headers,
  ) {
    final headerString = headers?.toString() ?? '';
    final authToken = authHeaders['Authorization'] ?? '';
    return '$path:$headerString:$authToken';
  }

  http.Response? _getCachedResponse(
    String path,
    Map<String, String> authHeaders,
    Map<String, String>? headers,
  ) {
    final key = _getCacheKey(path, authHeaders, headers);
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.response;
    }
    return null;
  }

  void _cacheResponse(
    String path,
    Map<String, String> authHeaders,
    Map<String, String>? headers,
    http.Response response,
    Duration duration,
  ) {
    final key = _getCacheKey(path, authHeaders, headers);
    _cache[key] = _CacheEntry(
      response: response,
      expiresAt: DateTime.now().add(duration),
    );

    // Clean up expired cache entries periodically
    if (_cache.length % 10 == 0) {
      _cleanCache();
    }
  }

  void _cleanCache() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    return _withRetry(() async {
      final authHeaders = await _authHeaders(headers);
      _logRequest('POST', path, authHeaders, body);

      final baseUrl = await _getBaseUrl();
      final encoded = body == null ? null : jsonEncode(body);

      // If offline, queue the request
      if (!_isOnline) {
        final completer = Completer<http.Response>();
        _requestQueue.add(
          _QueuedRequest(
            method: 'POST',
            path: path,
            body: body,
            headers: headers,
            completer: completer,
          ),
        );
        debugPrint('[Offline] POST $path - queued for processing');
        return await completer.future;
      }

      final completer = Completer<http.Response>();
      Timer? timeoutTimer;

      try {
        timeoutTimer = Timer(timeout, () {
          if (!completer.isCompleted) {
            completer.completeError(
              TimeoutException('Request timed out', timeout),
            );
          }
        });

        final response = await _withRefreshRetry(() async {
          if (encoded != null) {
            authHeaders['Content-Type'] = 'application/json';
          }

          final resp = await _client.post(
            Uri.parse(_joinUrl(baseUrl, path)),
            headers: authHeaders,
            body: encoded,
          );
          _logResponse('POST', path, resp);

          if (resp.statusCode >= 400) {
            throw ApiHttpException.fromResponse(resp);
          }

          return resp;
        });

        if (!completer.isCompleted) {
          completer.complete(response);
        }

        return response;
      } catch (error) {
        _logError('POST', path, error);
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        rethrow;
      } finally {
        timeoutTimer?.cancel();
      }
    });
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    return _withRetry(() async {
      final authHeaders = await _authHeaders(headers);
      _logRequest('PUT', path, authHeaders, body);

      final baseUrl = await _getBaseUrl();
      final encoded = body == null ? null : jsonEncode(body);

      // If offline, queue the request
      if (!_isOnline) {
        final completer = Completer<http.Response>();
        _requestQueue.add(
          _QueuedRequest(
            method: 'PUT',
            path: path,
            body: body,
            headers: headers,
            completer: completer,
          ),
        );
        debugPrint('[Offline] PUT $path - queued for processing');
        return await completer.future;
      }

      final completer = Completer<http.Response>();
      Timer? timeoutTimer;

      try {
        timeoutTimer = Timer(timeout, () {
          if (!completer.isCompleted) {
            completer.completeError(
              TimeoutException('Request timed out', timeout),
            );
          }
        });

        final response = await _withRefreshRetry(() async {
          if (encoded != null) {
            authHeaders['Content-Type'] = 'application/json';
          }

          final resp = await _client.put(
            Uri.parse(_joinUrl(baseUrl, path)),
            headers: authHeaders,
            body: encoded,
          );
          _logResponse('PUT', path, resp);

          if (resp.statusCode >= 400) {
            throw ApiHttpException.fromResponse(resp);
          }

          return resp;
        });

        if (!completer.isCompleted) {
          completer.complete(response);
        }

        return response;
      } catch (error) {
        _logError('PUT', path, error);
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        rethrow;
      } finally {
        timeoutTimer?.cancel();
      }
    });
  }

  Future<http.Response> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    return _withRetry(() async {
      final authHeaders = await _authHeaders(headers);
      _logRequest('DELETE', path, authHeaders, body);

      final baseUrl = await _getBaseUrl();
      final encoded = body == null ? null : jsonEncode(body);

      // If offline, queue the request
      if (!_isOnline) {
        final completer = Completer<http.Response>();
        _requestQueue.add(
          _QueuedRequest(
            method: 'DELETE',
            path: path,
            body: body,
            headers: headers,
            completer: completer,
          ),
        );
        debugPrint('[Offline] DELETE $path - queued for processing');
        return await completer.future;
      }

      final completer = Completer<http.Response>();
      Timer? timeoutTimer;

      try {
        timeoutTimer = Timer(timeout, () {
          if (!completer.isCompleted) {
            completer.completeError(
              TimeoutException('Request timed out', timeout),
            );
          }
        });

        final response = await _withRefreshRetry(() async {
          if (encoded != null) {
            authHeaders['Content-Type'] = 'application/json';
          }

          final resp = await _client.delete(
            Uri.parse(_joinUrl(baseUrl, path)),
            headers: authHeaders,
            body: encoded,
          );
          _logResponse('DELETE', path, resp);

          if (resp.statusCode >= 400) {
            throw ApiHttpException.fromResponse(resp);
          }

          return resp;
        });

        if (!completer.isCompleted) {
          completer.complete(response);
        }

        return response;
      } catch (error) {
        _logError('DELETE', path, error);
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        rethrow;
      } finally {
        timeoutTimer?.cancel();
      }
    });
  }

  // Logout method to revoke refresh tokens and clear storage
  Future<void> logout() async {
    try {
      final baseUrl = await _getBaseUrl();

      // On mobile, use body-based logout
      final refreshToken = await this.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client.post(
          Uri.parse(_joinUrl(baseUrl, '/api/auth/logout')),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      }
    } catch (e) {
      // Log error but don't throw - we want to clear local tokens regardless
      // Note: In production, consider using a proper logging service
      debugPrint('Logout API call failed: $e');
    } finally {
      // Always clear local tokens
      await clearToken();
      await clearRefreshToken();
    }
  }

  // JSON helpers
  Future<dynamic> getJson(String path, {Map<String, String>? headers}) async {
    final resp = await get(path, headers: headers);
    _throwIfNotOk(resp);
    return jsonDecode(resp.body);
  }

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final resp = await post(path, body: body, headers: headers);
    _throwIfNotOk(resp);
    return jsonDecode(resp.body);
  }

  void _throwIfNotOk(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      // Return the response object instead of throwing a generic exception
      // This allows more detailed error handling in the UI
      throw resp;
    }
  }

  Future<Map<String, String>> _authHeaders(Map<String, String>? headers) async {
    final h = {
      'x-client-type': 'mobile', // Mobile-only client type
      ...?headers,
    };
    final t = await token;
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Future<http.Response> _withRefreshRetry(
    Future<http.Response> Function() fn,
  ) async {
    final first = await fn();
    if (first.statusCode != 401) return first;

    // try refresh
    final baseUrl = await _getBaseUrl();

    // Detect platform and use appropriate refresh method
    if (kIsWeb) {
      // Web platform: use cookie-based refresh with CSRF support
      final csrfToken = await _getCsrfToken();
      final webClient = BrowserClient()..withCredentials = true;

      try {
        final refreshResp = await webClient.post(
          Uri.parse(_joinUrl(baseUrl, '/api/auth/refresh')),
          headers: {
            'Content-Type': 'application/json',
            if (csrfToken != null) 'X-CSRF-Token': csrfToken,
          },
        );

        if (refreshResp.statusCode >= 200 && refreshResp.statusCode < 300) {
          try {
            final data = jsonDecode(refreshResp.body) as Map<String, dynamic>;
            final newAccess = data['token']?.toString();

            if (newAccess != null && newAccess.isNotEmpty) {
              await setToken(newAccess);
              return await fn();
            }
          } catch (_) {}
        }
      } finally {
        webClient.close();
      }
    } else {
      // Mobile platform: use body-based refresh
      final rt = await refreshToken;
      if (rt == null || rt.isEmpty) return first;

      final refreshResp = await _client.post(
        Uri.parse(_joinUrl(baseUrl, '/api/auth/refresh')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': rt}),
      );

      if (refreshResp.statusCode >= 200 && refreshResp.statusCode < 300) {
        try {
          final data = jsonDecode(refreshResp.body) as Map<String, dynamic>;
          final newAccess = data['token']?.toString();
          final newRefresh = data['refresh_token']?.toString();

          if (newAccess != null && newAccess.isNotEmpty) {
            await setToken(newAccess);
            if (newRefresh != null && newRefresh.isNotEmpty) {
              await setRefreshToken(newRefresh);
            }
            return await fn();
          }
        } catch (_) {}
      }
    }
    return first;
  }

  // Helper method to get CSRF token for web platform
  Future<String?> _getCsrfToken() async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await _client.get(
        Uri.parse(_joinUrl(baseUrl, '/api/auth/csrf')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['csrf_token']?.toString();
      }
    } catch (_) {}
    return null;
  }
}
