// lib/core/auth_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _phoneNumber;
  final List<String> _scopes = [];
  final List<String> _roles = [];
  bool _isLoading = false;
  Timer? _tokenRefreshTimer;
  DateTime? _tokenExpiry;
  String? _lastError;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get phoneNumber => _phoneNumber;
  List<String> get scopes => List.unmodifiable(_scopes);
  List<String> get roles => List.unmodifiable(_roles);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  DateTime? get tokenExpiry => _tokenExpiry;

  // Check if user has required scope
  bool hasScope(String scope) => _scopes.contains(scope);

  // Check if user has any of the required scopes
  bool hasAnyScope(List<String> scopes) =>
      scopes.any((scope) => _scopes.contains(scope));

  // Check if user has required role
  bool hasRole(String role) => _roles.contains(role);

  // Decode JWT token and extract claims
  Map<String, dynamic>? _decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (middle part)
      final payload = parts[1];
      // Add padding if needed
      final paddedPayload = payload.padRight((payload.length + 3) & ~3, '=');
      final decoded = utf8.decode(base64Url.decode(paddedPayload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding JWT: $e');
      return null;
    }
  }

  // Extract user info from JWT token
  void _extractUserInfoFromToken(String token) {
    final claims = _decodeJWT(token);
    if (claims == null) return;

    // Extract user ID and phone number
    _userId = claims['sub']?.toString();
    _phoneNumber = claims['phone_number']?.toString();

    // Extract roles and scopes
    _roles.clear();
    _scopes.clear();

    // Extract roles
    if (claims['roles'] is List) {
      _roles.addAll((claims['roles'] as List).map((e) => e.toString()));
    } else if (claims['role'] != null) {
      _roles.add(claims['role'].toString());
    }

    // Extract scopes
    if (claims['scopes'] is List) {
      _scopes.addAll((claims['scopes'] as List).map((e) => e.toString()));
    }

    // Validate token expiration
    final exp = claims['exp'];
    if (exp != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      if (_tokenExpiry!.isBefore(DateTime.now())) {
        debugPrint('JWT token has expired');
        _clearAuth();
        return;
      }
      // Schedule token refresh before expiry (5 minutes before)
      _scheduleTokenRefresh();
    }

    debugPrint(
      'Extracted user info - ID: $_userId, Phone: $_phoneNumber, Roles: $_roles, Scopes: $_scopes',
    );
  }

  // Initialize auth state from stored token
  Future<void> initializeAuth() async {
    _setLoading(true);
    try {
      final token = await ApiClient.instance.token;
      if (token != null && token.isNotEmpty) {
        // Extract user info from JWT token
        _extractUserInfoFromToken(token);

        // Token exists, verify it's still valid by making a test request
        try {
          final response = await ApiClient.instance.get('/api/teams/my-team');
          if (response.statusCode == 200) {
            _setAuthenticated(true);
          } else if (response.statusCode == 401) {
            // Token is invalid, clear it
            await logout();
          }
        } catch (e) {
          // Network error or invalid token
          await logout();
        }
      } else {
        _setAuthenticated(false);
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _lastError = e.toString();
      _setAuthenticated(false);
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login(String phoneNumber, String password) async {
    _setLoading(true);
    try {
      final response = await ApiClient.instance.post(
        '/api/auth/login',
        body: {'phone_number': phoneNumber, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiClient.instance.setToken(data['token']);

        // Extract user info from JWT token
        _extractUserInfoFromToken(data['token']);

        _setAuthenticated(true);
        return true;
      } else {
        _setAuthenticated(false);
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _lastError = e.toString();
      _setAuthenticated(false);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user has all required scopes
  bool hasAllScopes(List<String> scopes) =>
      scopes.every((scope) => _scopes.contains(scope));

  // Get user role (for permission checking)
  String? getUserRole() => _roles.isNotEmpty ? _roles.first : null;

  // Check if token is about to expire
  bool isTokenExpiringSoon({Duration threshold = const Duration(minutes: 5)}) {
    if (_tokenExpiry == null) return false;
    return _tokenExpiry!.difference(DateTime.now()) < threshold;
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      await ApiClient.instance.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _clearAuth();
      _setLoading(false);
    }
  }

  // Schedule token refresh before expiry
  void _scheduleTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    if (_tokenExpiry == null) return;

    final timeUntilExpiry = _tokenExpiry!.difference(DateTime.now());
    final refreshTime = timeUntilExpiry - const Duration(minutes: 5);

    if (refreshTime.isNegative) {
      // Token expires in less than 5 minutes, refresh immediately
      _refreshToken();
    } else {
      _tokenRefreshTimer = Timer(refreshTime, _refreshToken);
    }
  }

  // Refresh access token using refresh token
  Future<void> _refreshToken() async {
    try {
      final response = await ApiClient.instance.post(
        '/api/auth/refresh',
        body: {'refresh_token': await ApiClient.instance.refreshToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await ApiClient.instance.setToken(newToken);
          _extractUserInfoFromToken(newToken);
          debugPrint('Token refreshed successfully');
        }
      } else {
        // Refresh failed, logout user
        await logout();
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      // Continue auth state, UI can handle offline scenarios
    }
  }

  // Clear authentication state
  void _clearAuth() {
    _isAuthenticated = false;
    _userId = null;
    _phoneNumber = null;
    _roles.clear();
    _scopes.clear();
    _tokenExpiry = null;
    _lastError = null;
    _tokenRefreshTimer?.cancel();
    notifyListeners();
  }

  // Refresh authentication state
  Future<void> refreshAuth() async {
    await initializeAuth();
  }

  // Sync state across app instances (for multi-window/tab scenarios)
  void syncAuthState(AuthProvider other) {
    _isAuthenticated = other._isAuthenticated;
    _userId = other._userId;
    _phoneNumber = other._phoneNumber;
    _roles.clear();
    _roles.addAll(other._roles);
    _scopes.clear();
    _scopes.addAll(other._scopes);
    _tokenExpiry = other._tokenExpiry;
    notifyListeners();
  }

  // Private methods
  void _setAuthenticated(bool authenticated) {
    if (_isAuthenticated != authenticated) {
      _isAuthenticated = authenticated;
      if (!authenticated) {
        _userId = null;
        _phoneNumber = null;
        _scopes.clear();
        _roles.clear();
        _tokenExpiry = null;
        _tokenRefreshTimer?.cancel();
        _lastError = null;
      }
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Dispose resources
  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}
