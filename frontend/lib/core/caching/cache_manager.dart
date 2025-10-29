import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages different types of caching in the app
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  static CacheManager get instance => _instance;

  late SharedPreferences _persistentCache;
  final Map<String, dynamic> _memoryCache = {};
  final _storage = const FlutterSecureStorage();

  bool _initialized = false;

  CacheManager._internal();

  Future<void> init() async {
    if (_initialized) return;
    _persistentCache = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // Memory Cache Operations
  Future<T?> getFromMemory<T>(String key) async {
    if (!_memoryCache.containsKey(key)) return null;

    final entry = _memoryCache[key] as CacheEntry<T>;
    if (entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }

    return entry.value;
  }

  Future<void> setInMemory<T>(
    String key,
    T value, {
    Duration expiry = const Duration(hours: 1),
  }) async {
    _memoryCache[key] = CacheEntry<T>(
      value: value,
      expiryTime: DateTime.now().add(expiry),
    );
  }

  // Persistent Cache Operations
  Future<T?> getFromPersistent<T>(String key) async {
    final data = _persistentCache.getString(key);
    if (data == null) return null;

    try {
      final entry = CacheEntry<T>.fromJson(
        jsonDecode(data) as Map<String, dynamic>,
      );
      if (entry.isExpired) {
        await _persistentCache.remove(key);
        return null;
      }
      return entry.value;
    } catch (e) {
      await _persistentCache.remove(key);
      return null;
    }
  }

  Future<void> setInPersistent<T>(
    String key,
    T value, {
    Duration expiry = const Duration(hours: 24),
  }) async {
    final entry = CacheEntry<T>(
      value: value,
      expiryTime: DateTime.now().add(expiry),
    );
    await _persistentCache.setString(key, jsonEncode(entry.toJson()));
  }

  // Secure Storage Operations
  Future<String?> getFromSecure(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> setInSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Combined Operations
  Future<T?> get<T>(String key) async {
    // Try memory first
    final memoryValue = await getFromMemory<T>(key);
    if (memoryValue != null) return memoryValue;

    // Try persistent cache
    final persistentValue = await getFromPersistent<T>(key);
    if (persistentValue != null) {
      // Cache in memory for faster subsequent access
      await setInMemory<T>(key, persistentValue);
      return persistentValue;
    }

    return null;
  }

  Future<void> set<T>(
    String key,
    T value, {
    Duration? memoryExpiry,
    Duration? persistentExpiry,
  }) async {
    if (memoryExpiry != null) {
      await setInMemory<T>(key, value, expiry: memoryExpiry);
    }

    if (persistentExpiry != null) {
      await setInPersistent<T>(key, value, expiry: persistentExpiry);
    }
  }

  // Cache Maintenance
  Future<void> clearMemoryCache() async {
    _memoryCache.clear();
  }

  Future<void> clearPersistentCache() async {
    await _persistentCache.clear();
  }

  Future<void> clearSecureStorage() async {
    await _storage.deleteAll();
  }

  Future<void> clearAll() async {
    await Future.wait([
      clearMemoryCache(),
      clearPersistentCache(),
      clearSecureStorage(),
    ]);
  }

  // Cache entry management
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _persistentCache.remove(key);
    await _storage.delete(key: key);
  }

  Future<void> removeExpired() async {
    // Remove expired memory cache entries
    _memoryCache.removeWhere((_, entry) => (entry as CacheEntry).isExpired);

    // Remove expired persistent cache entries
    final keys = _persistentCache.getKeys();
    for (final key in keys) {
      final data = _persistentCache.getString(key);
      if (data != null) {
        try {
          final entry = CacheEntry.fromJson(
            jsonDecode(data) as Map<String, dynamic>,
          );
          if (entry.isExpired) {
            await _persistentCache.remove(key);
          }
        } catch (e) {
          await _persistentCache.remove(key);
        }
      }
    }
  }
}

class CacheEntry<T> {
  final T value;
  final DateTime expiryTime;

  CacheEntry({required this.value, required this.expiryTime});

  bool get isExpired => DateTime.now().isAfter(expiryTime);

  Map<String, dynamic> toJson() => {
    'value': value,
    'expiryTime': expiryTime.toIso8601String(),
    'type': T.toString(),
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    final type = json['type'] as String;

    // Handle basic types
    T typedValue;
    if (T == String) {
      typedValue = value.toString() as T;
    } else if (T == int) {
      typedValue = (value is String ? int.parse(value) : value as int) as T;
    } else if (T == double) {
      typedValue =
          (value is String ? double.parse(value) : value as double) as T;
    } else if (T == bool) {
      typedValue =
          (value is String ? value.toLowerCase() == 'true' : value as bool)
              as T;
    } else if (T == List) {
      typedValue = (value is String ? jsonDecode(value) : value) as T;
    } else if (T == Map) {
      typedValue = (value is String ? jsonDecode(value) : value) as T;
    } else {
      // For complex objects, assume they can be decoded from a Map
      typedValue = value as T;
    }

    return CacheEntry(
      value: typedValue,
      expiryTime: DateTime.parse(json['expiryTime'] as String),
    );
  }
}
