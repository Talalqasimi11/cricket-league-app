// lib/core/cache_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class CacheService {
  // File-based cache keys for large datasets
  static const String _teamDataFile = 'cached_team_data.json';
  static const String _playersDataFile = 'cached_players_data.json';
  static const String _atomicTeamDataFile = 'cached_atomic_team_data.json';

  // Secure storage keys for small metadata
  static const String _cacheVersionKey = 'cache_version';
  static const String _cacheTimestampKey = 'cache_timestamp';

  // Cache TTL: 1 hour
  static const Duration _cacheTtl = Duration(hours: 1);
  static const String _currentCacheVersion = '1.0.0';

  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Directory? _cacheDirectory;

  // Get cache directory for file-based storage
  Future<Directory> _getCacheDirectory() async {
    _cacheDirectory ??= await getApplicationDocumentsDirectory();
    return _cacheDirectory!;
  }

  // Write to secure storage (for small metadata)
  Future<void> _writeToSecureStorage(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  // Read from secure storage (for small metadata)
  Future<String?> _readFromSecureStorage(String key) async {
    return await _secureStorage.read(key: key);
  }

  // Delete from secure storage (for small metadata)
  Future<void> _deleteFromSecureStorage(String key) async {
    await _secureStorage.delete(key: key);
  }

  // Write to file-based cache (for large datasets)
  Future<void> _writeToFileCache(String filename, String content) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final file = File('${cacheDir.path}/$filename');
      await file.writeAsString(content);
    } catch (e) {
      debugPrint('Failed to write to file cache: $e');
    }
  }

  // Read from file-based cache (for large datasets)
  Future<String?> _readFromFileCache(String filename) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final file = File('${cacheDir.path}/$filename');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('Failed to read from file cache: $e');
    }
    return null;
  }

  // Delete from file-based cache (for large datasets)
  Future<void> _deleteFromFileCache(String filename) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final file = File('${cacheDir.path}/$filename');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete from file cache: $e');
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

      await _writeToFileCache(_teamDataFile, jsonEncode(cacheData));
      await _writeToSecureStorage(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
      await _writeToSecureStorage(_cacheVersionKey, _currentCacheVersion);
    } catch (e) {
      // Cache write failure shouldn't break the app
      debugPrint('Failed to cache team data: $e');
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

      await _writeToFileCache(_playersDataFile, jsonEncode(cacheData));
    } catch (e) {
      // Cache write failure shouldn't break the app
      debugPrint('Failed to cache players data: $e');
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

      // Write atomic data to file cache
      await _writeToFileCache(_atomicTeamDataFile, jsonEncode(atomicData));

      // Also update individual caches for backward compatibility
      await cacheTeamData(teamData);
      await cachePlayersData(playersData);

      // Update global timestamp in secure storage
      await _writeToSecureStorage(_cacheTimestampKey, timestamp.toString());
      await _writeToSecureStorage(_cacheVersionKey, _currentCacheVersion);
    } catch (e) {
      // Cache write failure shouldn't break the app
      debugPrint('Failed to cache atomic team data: $e');
    }
  }

  /// Get atomically cached team and players data
  Future<Map<String, dynamic>?> getAtomicTeamAndPlayers() async {
    try {
      final cachedJson = await _readFromFileCache(_atomicTeamDataFile);
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
      final cachedJson = await _readFromFileCache(_teamDataFile);
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
      final cachedJson = await _readFromFileCache(_playersDataFile);
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
      final timestampStr = await _readFromSecureStorage(_cacheTimestampKey);
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
      await _deleteFromFileCache(_teamDataFile);
      await _deleteFromFileCache(_playersDataFile);
      await _deleteFromFileCache(_atomicTeamDataFile);
      await _deleteFromSecureStorage(_cacheTimestampKey);
      await _deleteFromSecureStorage(_cacheVersionKey);
    } catch (e) {
      // Cache clear failure shouldn't break the app
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Get cache age in minutes
  Future<int?> getCacheAgeMinutes() async {
    try {
      final timestampStr = await _readFromSecureStorage(_cacheTimestampKey);
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
