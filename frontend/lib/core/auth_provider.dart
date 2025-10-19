// lib/core/auth_provider.dart
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

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get phoneNumber => _phoneNumber;
  List<String> get scopes => List.unmodifiable(_scopes);
  List<String> get roles => List.unmodifiable(_roles);
  bool get isLoading => _isLoading;

  // Check if user has required scope
  bool hasScope(String scope) => _scopes.contains(scope);

  // Check if user has any of the required scopes
  bool hasAnyScope(List<String> scopes) =>
      scopes.any((scope) => _scopes.contains(scope));

  // Check if user has required role
  bool hasRole(String role) => _roles.contains(role);

  // Initialize auth state from stored token
  Future<void> initializeAuth() async {
    _setLoading(true);
    try {
      final token = await ApiClient.instance.token;
      if (token != null && token.isNotEmpty) {
        // Token exists, verify it's still valid by making a test request
        try {
          final response = await ApiClient.instance.get('/api/teams/my-team');
          if (response.statusCode == 200) {
            _setAuthenticated(true);
            // Extract user info from token if needed
            // For now, we'll rely on the API response
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

        // Extract user info from response
        if (data['user'] != null) {
          _userId = data['user']['id']?.toString();
          _phoneNumber = data['user']['phone_number'];
        }

        _setAuthenticated(true);
        return true;
      } else {
        _setAuthenticated(false);
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _setAuthenticated(false);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      await ApiClient.instance.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _setAuthenticated(false);
      _setLoading(false);
    }
  }

  // Refresh authentication state
  Future<void> refreshAuth() async {
    await initializeAuth();
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
}
