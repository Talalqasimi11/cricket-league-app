import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, debugPrint, kDebugMode;
import 'package:connectivity_plus/connectivity_plus.dart';
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

  String? _cachedBaseUrl;
  bool _isInitialized = false;
  late final http.Client _client;

  static String get baseUrl {
    return instance._cachedBaseUrl ?? instance.getPlatformDefaultUrl();
  }

  Future<void> init() async {
    if (_isInitialized) return;

    getConfiguredBaseUrl()
        .then((url) {
          _cachedBaseUrl = url;
          debugPrint('[ApiClient] Base URL configured: $url');
        })
        .catchError((error) {
          debugPrint('[ApiClient] Error configuring base URL: $error');
          _cachedBaseUrl = getPlatformDefaultUrl();
        });

    _initializeConnectivityListener();
    _isInitialized = true;
    debugPrint('[ApiClient] Init completed (isInitialized=true)');
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

      _isOnline = results.any((res) => res != ConnectivityResult.none);
      debugPrint('Connectivity changed: $_isOnline (results: $results)');

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

    if (defaultTargetPlatform == TargetPlatform.android) {
      const url = 'https://foveolar-louetta-unradiant.ngrok-free.dev';
      debugPrint('[Developer] Android detected, using ngrok URL: $url');
      return url;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      const url = 'http://localhost:5000';
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

  Future<void> setCustomBaseUrl(String url) async {
    final normalizedUrl = _normalizeUrl(url);
    await _writeToStorage('custom_api_url', normalizedUrl);
    _cachedBaseUrl = normalizedUrl;
  }

  Future<void> clearCustomBaseUrl() async {
    await _deleteFromStorage('custom_api_url');
    _cachedBaseUrl = getPlatformDefaultUrl();
  }

  Future<String> getConfiguredBaseUrl() async {
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return _normalizeUrl(envUrl);
    }

    final customUrl = await _readFromStorage('custom_api_url');
    if (customUrl != null && customUrl.isNotEmpty) {
      return _normalizeUrl(customUrl);
    }

    return getPlatformDefaultUrl();
  }

  Future<String> _getBaseUrl() async {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }
    return await getConfiguredBaseUrl();
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _writeToStorage(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> _readFromStorage(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> _deleteFromStorage(String key) async {
    await _storage.delete(key: key);
  }

  String _normalizeUrl(String url) {
    return url.trim().replaceAll(RegExp(r'/+$'), '');
  }

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
    }
  }

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

  // NEW: Validate if response is JSON
  bool _isJsonResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    return contentType.contains('application/json') || 
           contentType.contains('text/json');
  }

  // NEW: Safely decode JSON with validation
  dynamic _safeJsonDecode(http.Response response) {
    try {
      // Check if response body is empty
      if (response.body.isEmpty) {
        debugPrint('[ApiClient] Empty response body');
        return null;
      }

      // Validate content type
      if (!_isJsonResponse(response)) {
        debugPrint(
          '[ApiClient] Non-JSON response received: ${response.headers['content-type']}',
        );
        debugPrint('[ApiClient] Response body: ${response.body}');
        throw FormatException('Response is not JSON');
      }

      // Try to decode
      return jsonDecode(response.body);
    } on FormatException catch (e) {
      debugPrint('[ApiClient] JSON decode error: $e');
      debugPrint('[ApiClient] Response body: ${response.body}');
      rethrow;
    } catch (e) {
      debugPrint('[ApiClient] Unexpected error decoding JSON: $e');
      rethrow;
    }
  }

  // NEW: Validate cached response
  http.Response? _getValidCachedResponse(
    String path,
    Map<String, String> authHeaders,
    Map<String, String>? headers,
  ) {
    try {
      final key = _getCacheKey(path, authHeaders, headers);
      final entry = _cache[key];
      
      if (entry == null || entry.isExpired) {
        return null;
      }

      // Validate cached response body is still valid JSON
      if (_isJsonResponse(entry.response)) {
        try {
          _safeJsonDecode(entry.response);
          return entry.response;
        } catch (e) {
          debugPrint('[Cache] Cached response has invalid JSON, removing');
          _cache.remove(key);
          return null;
        }
      }

      return entry.response;
    } catch (e) {
      debugPrint('[Cache] Error retrieving cached response: $e');
      return null;
    }
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
          case 'UPLOAD':
            final uploadBody = request.body as Map<String, dynamic>;
            final file = uploadBody['file'];
            final fieldName = uploadBody['fieldName'] as String?;
            response = await uploadFile(
              request.path,
              file,
              fieldName: fieldName ?? 'file',
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

      // Check cache first if not forcing refresh - UPDATED
      if (!forceRefresh) {
        final cachedResponse = _getValidCachedResponse(path, authHeaders, headers);
        if (cachedResponse != null) {
          debugPrint('[Cache] GET $path - returning cached response');
          return cachedResponse;
        }
      }

      // If offline, return cached response or queue request - UPDATED
      if (!_isOnline) {
        final cachedResponse = _getValidCachedResponse(path, authHeaders, headers);
        if (cachedResponse != null) {
          debugPrint('[Offline] GET $path - returning cached response');
          return cachedResponse;
        }

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

          // Cache successful responses - UPDATED with validation
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            try {
              // Validate response before caching
              if (_isJsonResponse(resp)) {
                _safeJsonDecode(resp); // Validate it's valid JSON
                _cacheResponse(
                  path,
                  authHeaders,
                  headers,
                  resp,
                  cacheDuration ?? _defaultCacheDuration,
                );
              }
            } catch (e) {
              debugPrint('[Cache] Skipping cache due to invalid JSON: $e');
            }
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

  Future<void> logout() async {
    try {
      final baseUrl = await _getBaseUrl();
      final refreshToken = await this.refreshToken;
      
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client.post(
          Uri.parse(_joinUrl(baseUrl, '/api/auth/logout')),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );
      }
    } catch (e) {
      debugPrint('Logout API call failed: $e');
    } finally {
      await clearToken();
      await clearRefreshToken();
    }
  }

  // UPDATED: Safe JSON helpers with validation
  Future<dynamic> getJson(String path, {Map<String, String>? headers}) async {
    final resp = await get(path, headers: headers);
    _throwIfNotOk(resp);
    return _safeJsonDecode(resp);
  }

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final resp = await post(path, body: body, headers: headers);
    _throwIfNotOk(resp);
    return _safeJsonDecode(resp);
  }

  void _throwIfNotOk(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiHttpException.fromResponse(resp);
    }
  }

  Future<Map<String, String>> _authHeaders(Map<String, String>? headers) async {
    final h = {
      'x-client-type': 'mobile',
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

    final baseUrl = await _getBaseUrl();
    final rt = await refreshToken;
    if (rt == null || rt.isEmpty) return first;

    try {
      final refreshResp = await _client.post(
        Uri.parse(_joinUrl(baseUrl, '/api/auth/refresh')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': rt}),
      );

      if (refreshResp.statusCode >= 200 && refreshResp.statusCode < 300) {
        final data = _safeJsonDecode(refreshResp) as Map<String, dynamic>?;
        
        if (data != null) {
          final newAccess = data['token']?.toString();
          final newRefresh = data['refresh_token']?.toString();

          if (newAccess != null && newAccess.isNotEmpty) {
            await setToken(newAccess);
            if (newRefresh != null && newRefresh.isNotEmpty) {
              await setRefreshToken(newRefresh);
            }
            return await fn();
          }
        }
      }
    } catch (e) {
      debugPrint('[ApiClient] Error during token refresh: $e');
    }
    
    return first;
  }

  Future<bool> refreshTokensExplicitly() async {
    try {
      final baseUrl = await _getBaseUrl();
      final rt = await refreshToken;
      if (rt == null || rt.isEmpty) {
        debugPrint('[ApiClient] No refresh token available');
        return false;
      }

      final refreshResp = await _client.post(
        Uri.parse(_joinUrl(baseUrl, '/api/auth/refresh')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': rt}),
      );

      if (refreshResp.statusCode >= 200 && refreshResp.statusCode < 300) {
        try {
          final data = _safeJsonDecode(refreshResp) as Map<String, dynamic>?;
          
          if (data != null) {
            final newAccess = data['token']?.toString();
            final newRefresh = data['refresh_token']?.toString();

            if (newAccess != null && newAccess.isNotEmpty) {
              await setToken(newAccess);
              if (newRefresh != null && newRefresh.isNotEmpty) {
                await setRefreshToken(newRefresh);
              }
              debugPrint('[ApiClient] Tokens refreshed successfully via explicit refresh');
              return true;
            }
          }
        } catch (e) {
          debugPrint('[ApiClient] Error parsing refresh response: $e');
        }
      }

      debugPrint('[ApiClient] Token refresh failed: ${refreshResp.statusCode}');
      return false;
    } catch (e) {
      debugPrint('[ApiClient] Error during explicit token refresh: $e');
      return false;
    }
  }

  Future<http.Response> uploadFile(
    String path,
    dynamic file, {
    String fieldName = 'file',
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    return _withRetry(() async {
      final authHeaders = await _authHeaders(headers);
      _logRequest('UPLOAD', path, authHeaders, 'File: ${file.toString()}');

      final baseUrl = await _getBaseUrl();
      final url = _joinUrl(baseUrl, path);

      if (!_isOnline) {
        final completer = Completer<http.Response>();
        _requestQueue.add(
          _QueuedRequest(
            method: 'UPLOAD',
            path: path,
            body: {'file': file, 'fieldName': fieldName},
            headers: headers,
            completer: completer,
          ),
        );
        debugPrint('[Offline] UPLOAD $path - queued for processing');
        return await completer.future;
      }

      final completer = Completer<http.Response>();
      Timer? timeoutTimer;

      try {
        timeoutTimer = Timer(timeout, () {
          if (!completer.isCompleted) {
            completer.completeError(
              TimeoutException('Upload timed out', timeout),
            );
          }
        });

        final response = await _withRefreshRetry(() async {
          final request = http.MultipartRequest('POST', Uri.parse(url));
          request.headers.addAll(authHeaders);

          if (file is http.MultipartFile) {
            request.files.add(file);
          } else {
            request.files.add(await http.MultipartFile.fromPath(fieldName, file.toString()));
          }

          final streamedResponse = await request.send();
          final resp = await http.Response.fromStream(streamedResponse);
          _logResponse('UPLOAD', path, resp);

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
        _logError('UPLOAD', path, error);
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        rethrow;
      } finally {
        timeoutTimer?.cancel();
      }
    });
  }
}
