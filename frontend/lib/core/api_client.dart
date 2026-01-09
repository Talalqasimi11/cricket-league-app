import 'dart:async';
import 'dart:convert';
import 'dart:io'; // ✅ Required for File handling
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, debugPrint, kDebugMode;
import 'error_handler.dart';
import 'network_manager.dart';
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:mime/mime.dart'; // for lookupMimeType

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

  late final http.Client _client;
  bool _isInitialized = false;
  String? _cachedBaseUrl;

  // Sync online status from NetworkManager
  bool _isOnline = true;

  StreamSubscription<bool>? _connectivitySubscription;
  final List<_QueuedRequest> _requestQueue = [];
  final Map<String, _CacheEntry> _cache = {};

  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  static const Duration _defaultTimeout = Duration(
    seconds: 30,
  ); // Increased for uploads
  static const _maxRetries = 3;
  static const _retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // -------------------- Public Getters --------------------

  // ✅ Added: Helper to access base URL from anywhere (e.g. UI image helpers)
  static String get baseUrl =>
      instance._cachedBaseUrl ?? instance.getPlatformDefaultUrl();

  // -------------------- Initialization --------------------
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _cachedBaseUrl = await getConfiguredBaseUrl();
      debugPrint('[ApiClient] Base URL configured: $_cachedBaseUrl');
    } catch (e) {
      debugPrint('[ApiClient] Error configuring base URL: $e');
      _cachedBaseUrl = getPlatformDefaultUrl();
    }

    // Sync initial state from NetworkManager
    _isOnline = NetworkManager.instance.hasConnection;
    _initializeConnectivityListener();

    _isInitialized = true;
  }

  void _initializeConnectivityListener() {
    _connectivitySubscription = NetworkManager.instance.onConnectionChanged.listen((
      isOnline,
    ) {
      final wasOnline = _isOnline;
      _isOnline = isOnline;

      // If we just came back online, process the queue
      if (!wasOnline && _isOnline) {
        debugPrint(
          '[ApiClient] Connection restored. Processing ${_requestQueue.length} queued requests.',
        );
        _processQueuedRequests();
      }
      debugPrint('[ApiClient] Online status changed: $_isOnline');
    });
  }

  void dispose() {
    _client.close();
    _connectivitySubscription?.cancel();
    _requestQueue.clear();
    _cache.clear();
    debugPrint('[ApiClient] Disposed');
  }

  // -------------------- Base URL & Storage --------------------
  String getPlatformDefaultUrl() {
    return 'http://13.62.18.120:3000';
  }

  Future<void> setCustomBaseUrl(String url) async {
    _cachedBaseUrl = _normalizeUrl(url);
    await _storage.write(key: 'custom_api_url', value: _cachedBaseUrl);
  }

  Future<void> clearCustomBaseUrl() async {
    await _storage.delete(key: 'custom_api_url');
    _cachedBaseUrl = getPlatformDefaultUrl();
  }

  Future<String> getConfiguredBaseUrl() async {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return _normalizeUrl(envUrl);

    final storedUrl = await _storage.read(key: 'custom_api_url');
    if (storedUrl != null && storedUrl.isNotEmpty) {
      return _normalizeUrl(storedUrl);
    }

    return getPlatformDefaultUrl();
  }

  Future<String> _getBaseUrl() async =>
      _cachedBaseUrl ?? await getConfiguredBaseUrl();
  String _normalizeUrl(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');
  String _joinUrl(String base, String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '${_normalizeUrl(base)}$normalizedPath';
  }

  // -------------------- Token Management --------------------
  Future<String?> get token async => await _storage.read(key: 'jwt_token');
  Future<void> setToken(String token) async =>
      await _storage.write(key: 'jwt_token', value: token);
  Future<void> clearToken() async => await _storage.delete(key: 'jwt_token');

  Future<String?> get refreshToken async =>
      await _storage.read(key: 'refresh_token');
  Future<void> setRefreshToken(String token) async =>
      await _storage.write(key: 'refresh_token', value: token);
  Future<void> clearRefreshToken() async =>
      await _storage.delete(key: 'refresh_token');

  Future<Map<String, String>> _authHeaders(Map<String, String>? headers) async {
    final h = {'x-client-type': 'mobile', ...?headers};
    final t = await token;
    if (t?.isNotEmpty == true) h['Authorization'] = 'Bearer $t';
    return h;
  }

  // -------------------- Request Helpers --------------------
  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    Exception? lastError;
    for (var i = 0; i < _maxRetries; i++) {
      try {
        return await fn();
      } on ApiHttpException {
        rethrow;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (i < _maxRetries - 1) await Future.delayed(_retryDelays[i]);
      }
    }
    throw lastError ?? Exception('Request failed after $_maxRetries retries');
  }

  bool _isJsonResponse(http.Response resp) {
    final contentType = resp.headers['content-type'] ?? '';
    return contentType.contains('application/json') ||
        contentType.contains('text/json');
  }

  dynamic _safeJsonDecode(http.Response resp) {
    if (resp.body.isEmpty) return null;
    if (!_isJsonResponse(resp)) {
      // Allow pass-through for non-JSON but warn
      return resp.body;
    }
    return jsonDecode(resp.body);
  }

  String _getCacheKey(
    String path,
    Map<String, String> authHeaders,
    Map<String, String>? headers,
  ) {
    return '$path:${headers?.toString() ?? ""}:${authHeaders['Authorization'] ?? ""}';
  }

  http.Response? _getValidCachedResponse(
    String path,
    Map<String, String> authHeaders,
    Map<String, String>? headers,
  ) {
    final key = _getCacheKey(path, authHeaders, headers);
    final entry = _cache[key];
    if (entry == null || entry.isExpired) return null;
    try {
      return entry.response;
    } catch (_) {
      _cache.remove(key);
      return null;
    }
  }

  void _cacheResponse(
    String path,
    Map<String, String> authHeaders,
    Map<String, String>? headers,
    http.Response resp,
    Duration duration,
  ) {
    final key = _getCacheKey(path, authHeaders, headers);
    _cache[key] = _CacheEntry(
      response: resp,
      expiresAt: DateTime.now().add(duration),
    );
  }

  void _logRequest(
    String method,
    String path,
    Map<String, String> headers, [
    Object? body,
  ]) {
    if (kDebugMode) {
      debugPrint('[Request] $method $path');
      if (body != null) {
        debugPrint(
          '  Body (snippet): ${body.toString().substring(0, body.toString().length > 200 ? 200 : body.toString().length)}...',
        );
      }
    }
  }

  Future<void> _processQueuedRequests() async {
    final queue = List.from(_requestQueue);
    _requestQueue.clear();

    for (final request in queue) {
      try {
        http.Response response;
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
            response = await uploadFile(
              request.path,
              uploadBody['file'],
              fieldName: uploadBody['fieldName'],
              headers: request.headers,
            );
            break;
          default:
            throw Exception('Unknown queued request method: ${request.method}');
        }
        if (!request.completer.isCompleted) {
          request.completer.complete(response);
        }
      } catch (e) {
        if (!request.completer.isCompleted) request.completer.completeError(e);
      }
    }
  }

  // -------------------- HTTP Methods --------------------
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

      if (!forceRefresh) {
        final cached = _getValidCachedResponse(path, authHeaders, headers);
        if (cached != null) return cached;
      }

      if (!_isOnline && path != '/health') {
        final cached = _getValidCachedResponse(path, authHeaders, headers);
        if (cached != null) return cached;

        final completer = Completer<http.Response>();
        _requestQueue.add(
          _QueuedRequest(
            method: 'GET',
            path: path,
            headers: headers,
            completer: completer,
          ),
        );
        return await completer.future;
      }

      final resp = await _withRefreshRetry(
        () async => await _client
            .get(Uri.parse(url), headers: authHeaders)
            .timeout(timeout),
      );
      if (resp.statusCode >= 200 &&
          resp.statusCode < 300 &&
          _isJsonResponse(resp)) {
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
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    return _sendWithBody('POST', path, body, headers);
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    return _sendWithBody('PUT', path, body, headers);
  }

  Future<http.Response> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    return _sendWithBody('DELETE', path, body, headers);
  }

  Future<http.Response> _sendWithBody(
    String method,
    String path,
    Object? body,
    Map<String, String>? headers,
  ) async {
    return _withRetry(() async {
      final authHeaders = await _authHeaders(headers);
      final encoded = body != null ? jsonEncode(body) : null;

      if (!_isOnline) {
        final completer = Completer<http.Response>();
        _requestQueue.add(
          _QueuedRequest(
            method: method,
            path: path,
            body: body,
            headers: headers,
            completer: completer,
          ),
        );
        return await completer.future;
      }

      final baseUrl = await _getBaseUrl();
      final url = _joinUrl(baseUrl, path);

      if (encoded != null) authHeaders['Content-Type'] = 'application/json';
      _logRequest(method, path, authHeaders, encoded);

      final resp = await _withRefreshRetry(() async {
        switch (method) {
          case 'POST':
            return await _client.post(
              Uri.parse(url),
              headers: authHeaders,
              body: encoded,
            );
          case 'PUT':
            return await _client.put(
              Uri.parse(url),
              headers: authHeaders,
              body: encoded,
            );
          case 'DELETE':
            return await _client.delete(
              Uri.parse(url),
              headers: authHeaders,
              body: encoded,
            );
          default:
            throw Exception('Unsupported method $method');
        }
      });

      if (resp.statusCode >= 400) throw ApiHttpException.fromResponse(resp);
      return resp;
    });
  }

  // -------------------- File Upload --------------------
  Future<http.Response> uploadFile(
    String path,
    dynamic file, {
    String fieldName = 'file',
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
  }) async {
    return _withRetry(() async {
      final authHeaders = await _authHeaders(headers);
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
        return await completer.future;
      }

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(authHeaders);

      // --- IMPROVED FILE HANDLING START ---
      if (file is File) {
        // 1. Detect MIME type (e.g., image/jpeg, image/png)
        final mimeType = lookupMimeType(file.path);
        MediaType? contentType;

        if (mimeType != null) {
          final split = mimeType.split('/');
          contentType = MediaType(split[0], split[1]);
        }

        // 2. Attach file with Content-Type
        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            file.path,
            contentType: contentType, // <--- CRITICAL FOR BACKEND SECURITY
          ),
        );
      } else if (file is String) {
        if (File(file).existsSync()) {
          // Same logic for String paths
          final mimeType = lookupMimeType(file);
          MediaType? contentType;
          if (mimeType != null) {
            final split = mimeType.split('/');
            contentType = MediaType(split[0], split[1]);
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              fieldName,
              file,
              contentType: contentType,
            ),
          );
        } else {
          throw ArgumentError(
            "File path invalid or file does not exist: $file",
          );
        }
      } else if (file is http.MultipartFile) {
        request.files.add(file);
      } else {
        throw ArgumentError('Unsupported file type: ${file.runtimeType}');
      }
      // --- IMPROVED FILE HANDLING END ---

      final streamedResp = await request.send();
      final resp = await http.Response.fromStream(streamedResp);

      if (resp.statusCode >= 400) throw ApiHttpException.fromResponse(resp);
      return resp;
    });
  }

  // -------------------- Convenience JSON --------------------
  Future<dynamic> getJson(String path, {Map<String, String>? headers}) async {
    final resp = await get(path, headers: headers);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiHttpException.fromResponse(resp);
    }
    return _safeJsonDecode(resp);
  }

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final resp = await post(path, body: body, headers: headers);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiHttpException.fromResponse(resp);
    }
    return _safeJsonDecode(resp);
  }

  // -------------------- Logout --------------------
  Future<void> logout() async {
    try {
      final rt = await refreshToken;
      if (rt != null && rt.isNotEmpty) {
        await _client.post(
          Uri.parse(_joinUrl(await _getBaseUrl(), '/api/auth/logout')),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': rt}),
        );
      }
    } catch (e) {
      debugPrint('[ApiClient] Logout failed: $e');
    } finally {
      await clearToken();
      await clearRefreshToken();
    }
  }

  // -------------------- Auth Failure Stream --------------------
  final _authFailureController = StreamController<void>.broadcast();
  Stream<void> get onAuthFailure => _authFailureController.stream;

  // -------------------- Token Refresh --------------------
  Future<bool> refreshTokens() async {
    final rt = await refreshToken;
    if (rt == null || rt.isEmpty) return false;

    try {
      final refreshResp = await _client.post(
        Uri.parse(_joinUrl(await _getBaseUrl(), '/api/auth/refresh')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': rt}),
      );

      if (refreshResp.statusCode >= 200 && refreshResp.statusCode < 300) {
        final data = jsonDecode(refreshResp.body) as Map<String, dynamic>;
        final newAccess = data['token']?.toString();
        final newRefresh = data['refresh_token']?.toString();

        if (newAccess != null && newAccess.isNotEmpty) {
          await setToken(newAccess);
          if (newRefresh != null && newRefresh.isNotEmpty) {
            await setRefreshToken(newRefresh);
          }
          debugPrint('[ApiClient] Tokens refreshed successfully.');
          return true;
        }
      }
      debugPrint(
        '[ApiClient] Token refresh failed with status: ${refreshResp.statusCode}',
      );
      _authFailureController.add(null); // Notify auth failure
      return false;
    } catch (e) {
      debugPrint('[ApiClient] Token refresh failed: $e');
      return false;
    }
  }

  Future<http.Response> _withRefreshRetry(
    Future<http.Response> Function() fn,
  ) async {
    final first = await fn();
    if (first.statusCode != 401) return first;

    final rt = await refreshToken;
    if (rt == null || rt.isEmpty) {
      _authFailureController.add(null); // Notify auth failure
      return first;
    }

    try {
      final refreshResp = await _client.post(
        Uri.parse(_joinUrl(await _getBaseUrl(), '/api/auth/refresh')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': rt}),
      );
      if (refreshResp.statusCode >= 200 && refreshResp.statusCode < 300) {
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
      }
    } catch (e) {
      debugPrint('[ApiClient] Token refresh failed: $e');
    }

    _authFailureController.add(
      null,
    ); // Notify auth failure after failed refresh attempt
    return first;
  }
}
