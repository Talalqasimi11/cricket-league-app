import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  ApiClient._();

  static const String baseUrl =
      'http://localhost:3000/api'; 
  final http.Client _httpClient = http.Client();

  final Map<String, String> _defaultHeaders = {'Content-Type': 'application/json'};

  void setAuthToken(String token) {
    _defaultHeaders['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _defaultHeaders.remove('Authorization');
  }

  Future<void> logout() async {
    clearAuthToken();
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'jwt_token');
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _httpClient.get(
      uri,
      headers: {..._defaultHeaders, ...?headers},
    );
  }

  Future<http.Response> post(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _httpClient.post(
      uri,
      body: body != null ? json.encode(body) : null,
      headers: {..._defaultHeaders, ...?headers},
    );
  }

  Future<http.Response> put(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _httpClient.put(
      uri,
      body: body != null ? json.encode(body) : null,
      headers: {..._defaultHeaders, ...?headers},
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await _httpClient.delete(
      uri,
      headers: {..._defaultHeaders, ...?headers},
    );
  }

  void dispose() {
    _httpClient.close();
  }
}