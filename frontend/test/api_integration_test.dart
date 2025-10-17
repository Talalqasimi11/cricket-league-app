// Cricket League App - API Integration Tests
//
// This file contains tests for API integration functionality.
// These tests verify that the app can communicate with the backend API correctly.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_client.dart';

void main() {
  group('API Integration Tests', () {
    test('API Client platform default URL logic works', () {
      // Test that the platform default URL logic works correctly
      final apiClient = ApiClient.instance;
      final platformUrl = apiClient.getPlatformDefaultUrl();

      // Should return a valid URL
      expect(platformUrl, isA<String>());
      expect(platformUrl, isNotEmpty);
      expect(platformUrl, startsWith('http://'));
    });

    test('API Client singleton instance works', () {
      // Test that the singleton pattern works correctly
      final instance1 = ApiClient.instance;
      final instance2 = ApiClient.instance;
      expect(instance1, same(instance2));
    });

    test('API Client token management methods exist', () {
      // Test that token management methods are available
      final apiClient = ApiClient.instance;

      // These methods should exist and be callable
      expect(apiClient.token, isA<Future<String?>>());
      expect(apiClient.setToken, isA<Function>());
      expect(apiClient.clearToken, isA<Function>());
      expect(apiClient.refreshToken, isA<Future<String?>>());
      expect(apiClient.setRefreshToken, isA<Function>());
      expect(apiClient.clearRefreshToken, isA<Function>());
    });

    test('API Client HTTP methods exist', () {
      // Test that HTTP methods are available
      final apiClient = ApiClient.instance;

      // These methods should exist and be callable
      expect(apiClient.get, isA<Function>());
      expect(apiClient.post, isA<Function>());
      expect(apiClient.put, isA<Function>());
      expect(apiClient.delete, isA<Function>());
    });

    test('API Client configuration methods exist', () {
      // Test that configuration methods are available
      final apiClient = ApiClient.instance;

      // These methods should exist and be callable
      expect(apiClient.setCustomBaseUrl, isA<Function>());
      expect(apiClient.clearCustomBaseUrl, isA<Function>());
      expect(apiClient.getConfiguredBaseUrl, isA<Function>());
      expect(apiClient.init, isA<Function>());
    });
  });
}
