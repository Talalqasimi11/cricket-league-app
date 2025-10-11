import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // TODO: adjust this for your environment. For Android emulator use 10.0.2.2
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> get token async => await _storage.read(key: 'jwt_token');
  Future<void> setToken(String token) => _storage.write(key: 'jwt_token', value: token);
  Future<void> clearToken() => _storage.delete(key: 'jwt_token');

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    final authHeaders = await _authHeaders(headers);
    return http.get(Uri.parse('$baseUrl$path'), headers: authHeaders);
  }

  Future<http.Response> post(String path, {Object? body, Map<String, String>? headers}) async {
    final authHeaders = await _authHeaders(headers);
    return http.post(Uri.parse('$baseUrl$path'), headers: authHeaders, body: jsonEncode(body));
  }

  Future<http.Response> put(String path, {Object? body, Map<String, String>? headers}) async {
    final authHeaders = await _authHeaders(headers);
    return http.put(Uri.parse('$baseUrl$path'), headers: authHeaders, body: jsonEncode(body));
  }

  Future<http.Response> delete(String path, {Object? body, Map<String, String>? headers}) async {
    final authHeaders = await _authHeaders(headers);
    return http.delete(Uri.parse('$baseUrl$path'), headers: authHeaders, body: jsonEncode(body));
  }

  Future<Map<String, String>> _authHeaders(Map<String, String>? headers) async {
    final h = {
      'Content-Type': 'application/json',
      ...?headers,
    };
    final t = await token;
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }
}
