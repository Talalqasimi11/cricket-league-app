import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // Cached base URL for synchronous access
  String? _cachedBaseUrl;
  bool _isInitialized = false;

  // Platform-aware base URL detection
  static String get baseUrl {
    return instance._cachedBaseUrl ?? instance.getPlatformDefaultUrl();
  }

  // Initialize the cached base URL at app startup
  Future<void> init() async {
    if (_isInitialized) return;
    _cachedBaseUrl = await getConfiguredBaseUrl();
    _isInitialized = true;
  }

  String getPlatformDefaultUrl() {
    // Platform-aware detection using web-safe methods
    if (kIsWeb) {
      // For web platform
      return 'http://localhost:5000';
    } else {
      // For mobile and desktop platforms
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:5000'; // Android emulator
      } else {
        return 'http://localhost:5000'; // iOS, Windows, macOS, Linux
      }
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
  SharedPreferences? _prefs;

  // Web-safe storage abstraction
  Future<void> _initStorage() async {
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
    }
  }

  Future<void> _writeToStorage(String key, String value) async {
    await _initStorage();
    if (kIsWeb) {
      await _prefs!.setString(key, value);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<String?> _readFromStorage(String key) async {
    await _initStorage();
    if (kIsWeb) {
      return _prefs!.getString(key);
    } else {
      return await _storage.read(key: key);
    }
  }

  Future<void> _deleteFromStorage(String key) async {
    await _initStorage();
    if (kIsWeb) {
      await _prefs!.remove(key);
    } else {
      await _storage.delete(key: key);
    }
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

  Future<String?> get token async => await _storage.read(key: 'jwt_token');
  Future<void> setToken(String token) =>
      _storage.write(key: 'jwt_token', value: token);
  Future<void> clearToken() => _storage.delete(key: 'jwt_token');
  Future<String?> get refreshToken async =>
      await _storage.read(key: 'refresh_token');
  Future<void> setRefreshToken(String token) =>
      _storage.write(key: 'refresh_token', value: token);
  Future<void> clearRefreshToken() => _storage.delete(key: 'refresh_token');

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    return _withRefreshRetry(() async {
      final authHeaders = await _authHeaders(headers);
      final baseUrl = await _getBaseUrl();
      return http.get(Uri.parse(_joinUrl(baseUrl, path)), headers: authHeaders);
    });
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _withRefreshRetry(() async {
      final authHeaders = await _authHeaders(headers);
      final baseUrl = await _getBaseUrl();
      final encoded = body == null ? null : jsonEncode(body);
      return http.post(
        Uri.parse(_joinUrl(baseUrl, path)),
        headers: authHeaders,
        body: encoded,
      );
    });
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _withRefreshRetry(() async {
      final authHeaders = await _authHeaders(headers);
      final baseUrl = await _getBaseUrl();
      final encoded = body == null ? null : jsonEncode(body);
      return http.put(
        Uri.parse(_joinUrl(baseUrl, path)),
        headers: authHeaders,
        body: encoded,
      );
    });
  }

  Future<http.Response> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _withRefreshRetry(() async {
      final authHeaders = await _authHeaders(headers);
      final baseUrl = await _getBaseUrl();
      final encoded = body == null ? null : jsonEncode(body);
      return http.delete(
        Uri.parse(_joinUrl(baseUrl, path)),
        headers: authHeaders,
        body: encoded,
      );
    });
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
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<Map<String, String>> _authHeaders(Map<String, String>? headers) async {
    final h = {'Content-Type': 'application/json', ...?headers};
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
    final rt = await refreshToken;
    if (rt == null || rt.isEmpty) return first;
    final baseUrl = await _getBaseUrl();
    final refreshResp = await http.post(
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
    return first;
  }
}
