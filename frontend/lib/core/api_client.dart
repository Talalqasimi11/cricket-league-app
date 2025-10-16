import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // Platform-aware base URL detection
  static String get baseUrl {
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Detect Android emulator and use 10.0.2.2:5000
    // For other platforms, use localhost:5000
    return 'http://10.0.2.2:5000';
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
      return http.get(Uri.parse('$baseUrl$path'), headers: authHeaders);
    });
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _withRefreshRetry(() async {
      final authHeaders = await _authHeaders(headers);
      return http.post(
        Uri.parse('$baseUrl$path'),
        headers: authHeaders,
        body: jsonEncode(body),
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
      return http.put(
        Uri.parse('$baseUrl$path'),
        headers: authHeaders,
        body: jsonEncode(body),
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
      return http.delete(
        Uri.parse('$baseUrl$path'),
        headers: authHeaders,
        body: jsonEncode(body),
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
    final refreshResp = await http.post(
      Uri.parse('$baseUrl/api/auth/refresh'),
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
