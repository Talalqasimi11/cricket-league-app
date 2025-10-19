// lib/core/cache_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheService {
  static const String _teamDataKey = 'cached_team_data';
  static const String _playersDataKey = 'cached_players_data';
  static const String _atomicTeamDataKey = 'cached_atomic_team_data';
  static const String _cacheVersionKey = 'cache_version';
  static const String _cacheTimestampKey = 'cache_timestamp';

  // Cache TTL: 1 hour
  static const Duration _cacheTtl = Duration(hours: 1);
  static const String _currentCacheVersion = '1.0.0';

  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _readFromStorage(String key) async {
    await _initStorage();
    if (kIsWeb) {
      return _prefs!.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  Future<void> _deleteFromStorage(String key) async {
    await _initStorage();
    if (kIsWeb) {
      await _prefs!.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  /// Sanitize team data by removing sensitive information
  Map<String, dynamic> _sanitizeTeamData(Map<String, dynamic> teamData) {
    final sanitized = Map<String, dynamic>.from(teamData);
    // Remove sensitive fields that shouldn't be cached
    sanitized.remove('owner_phone');
    sanitized.remove('captain_phone');
    sanitized.remove('password');
    sanitized.remove('password_hash');
    return sanitized;
  }

  /// Cache team data with timestamp and version
  Future<void> cacheTeamData(Map<String, dynamic> teamData) async {
    try {
      final sanitizedData = _sanitizeTeamData(teamData);
      final cacheData = {
        'data': sanitizedData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': _currentCacheVersion,
      };

      await _writeToStorage(_teamDataKey, jsonEncode(cacheData));
      await _writeToStorage(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
      await _writeToStorage(_cacheVersionKey, _currentCacheVersion);
    } catch (e) {
      // Cache write failure shouldn't break the app
      print('Failed to cache team data: $e');
    }
  }

  /// Cache players data with timestamp and version
  Future<void> cachePlayersData(List<Map<String, dynamic>> playersData) async {
    try {
      final cacheData = {
        'data': playersData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': _currentCacheVersion,
      };

      await _writeToStorage(_playersDataKey, jsonEncode(cacheData));
    } catch (e) {
      // Cache write failure shouldn't break the app
      print('Failed to cache players data: $e');
    }
  }

  /// Atomically cache both team and players data together to prevent race conditions
  Future<void> setTeamAndPlayers({
    required Map<String, dynamic> teamData,
    required List<Map<String, dynamic>> playersData,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedTeamData = _sanitizeTeamData(teamData);
      final atomicData = {
        'team': sanitizedTeamData,
        'players': playersData,
        'timestamp': timestamp,
        'version': _currentCacheVersion,
      };

      // Write atomic data
      await _writeToStorage(_atomicTeamDataKey, jsonEncode(atomicData));

      // Also update individual caches for backward compatibility
      await cacheTeamData(teamData);
      await cachePlayersData(playersData);

      // Update global timestamp
      await _writeToStorage(_cacheTimestampKey, timestamp.toString());
      await _writeToStorage(_cacheVersionKey, _currentCacheVersion);
    } catch (e) {
      // Cache write failure shouldn't break the app
      print('Failed to cache atomic team data: $e');
    }
  }

  /// Get atomically cached team and players data
  Future<Map<String, dynamic>?> getAtomicTeamAndPlayers() async {
    try {
      final cachedJson = await _readFromStorage(_atomicTeamDataKey);
      if (cachedJson == null) return null;

      final cacheData = jsonDecode(cachedJson) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int?;
      final version = cacheData['version'] as String?;

      // Check version compatibility
      if (version != _currentCacheVersion) {
        await clearCache();
        return null;
      }

      // Check TTL
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        if (now.difference(cacheTime) > _cacheTtl) {
          await clearCache();
          return null;
        }
      }

      return cacheData;
    } catch (e) {
      // Cache read failure - clear cache and return null
      await clearCache();
      return null;
    }
  }

  /// Get cached team data if valid
  Future<Map<String, dynamic>?> getCachedTeamData() async {
    try {
      final cachedJson = await _readFromStorage(_teamDataKey);
      if (cachedJson == null) return null;

      final cacheData = jsonDecode(cachedJson) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int?;
      final version = cacheData['version'] as String?;

      // Check version compatibility
      if (version != _currentCacheVersion) {
        await clearCache();
        return null;
      }

      // Check TTL
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        if (now.difference(cacheTime) > _cacheTtl) {
          await clearCache();
          return null;
        }
      }

      return cacheData['data'] as Map<String, dynamic>?;
    } catch (e) {
      // Cache read failure - clear cache and return null
      await clearCache();
      return null;
    }
  }

  /// Get cached players data if valid
  Future<List<Map<String, dynamic>>?> getCachedPlayersData() async {
    try {
      final cachedJson = await _readFromStorage(_playersDataKey);
      if (cachedJson == null) return null;

      final cacheData = jsonDecode(cachedJson) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int?;
      final version = cacheData['version'] as String?;

      // Check version compatibility
      if (version != _currentCacheVersion) {
        await clearCache();
        return null;
      }

      // Check TTL
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        if (now.difference(cacheTime) > _cacheTtl) {
          await clearCache();
          return null;
        }
      }

      return (cacheData['data'] as List?)?.cast<Map<String, dynamic>>();
    } catch (e) {
      // Cache read failure - clear cache and return null
      await clearCache();
      return null;
    }
  }

  /// Check if cache is valid and not expired
  Future<bool> isCacheValid() async {
    try {
      final timestampStr = await _readFromStorage(_cacheTimestampKey);
      if (timestampStr == null) return false;

      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      return now.difference(cacheTime) <= _cacheTtl;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _deleteFromStorage(_teamDataKey);
      await _deleteFromStorage(_playersDataKey);
      await _deleteFromStorage(_atomicTeamDataKey);
      await _deleteFromStorage(_cacheTimestampKey);
      await _deleteFromStorage(_cacheVersionKey);
    } catch (e) {
      // Cache clear failure shouldn't break the app
      print('Failed to clear cache: $e');
    }
  }

  /// Get cache age in minutes
  Future<int?> getCacheAgeMinutes() async {
    try {
      final timestampStr = await _readFromStorage(_cacheTimestampKey);
      if (timestampStr == null) return null;

      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      return now.difference(cacheTime).inMinutes;
    } catch (e) {
      return null;
    }
  }
}
