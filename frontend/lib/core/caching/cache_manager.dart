import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Cache Manager handling Memory, Disk (Prefs), File (Large Data), and Secure Storage.
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  static CacheManager get instance => _instance;

  late SharedPreferences _persistentCache;
  final Map<String, dynamic> _memoryCache = {};
  final _storage = const FlutterSecureStorage();
  Directory? _fileCacheDir;

  bool _initialized = false;
  static const String _version = '1.0.0';

  CacheManager._internal();

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Initialize concurrently for performance
      await Future.wait([
        SharedPreferences.getInstance().then((prefs) => _persistentCache = prefs),
        getApplicationDocumentsDirectory().then((dir) => _fileCacheDir = dir),
      ]);
      _initialized = true;
      debugPrint('[CacheManager] Initialized');
    } catch (e) {
      debugPrint('[CacheManager] Initialization failed: $e');
      // Fallback: try serial initialization
      try {
        _persistentCache = await SharedPreferences.getInstance();
        _fileCacheDir = await getApplicationDocumentsDirectory();
        _initialized = true;
      } catch (e2) {
        debugPrint('[CacheManager] Fatal initialization error: $e2');
      }
    }
  }

  // ==========================================
  // UNIFIED API (Matches ApiService calls)
  // ==========================================

  /// Generic GET: Tries Memory -> Persistent -> File
  Future<T?> get<T>(String key) async {
    if (!_initialized) await init();

    // 1. Try Memory (Fastest)
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key] as CacheEntry<T>;
      if (!entry.isExpired) return entry.value;
      _memoryCache.remove(key);
    }

    // 2. Try Persistent (SharedPrefs) - Good for simple types
    final prefData = _persistentCache.getString(key);
    if (prefData != null) {
      try {
        final entry = CacheEntry<T>.fromJson(jsonDecode(prefData) as Map<String, dynamic>);
        if (!entry.isExpired) {
          // Refresh memory cache
          _memoryCache[key] = entry;
          return entry.value;
        } else {
          await _persistentCache.remove(key);
        }
      } catch (_) {
        await _persistentCache.remove(key);
      }
    }

    // 3. Try File (Good for large Lists/Maps)
    // Only attempt file read if T is dynamic, List, or Map to avoid unnecessary I/O
    if (T == List || T == Map || T == dynamic) {
      return await _getFromFile<T>(key);
    }

    return null;
  }

  /// Generic SET: Saves to Memory and (Persistent or File based on type/size)
  Future<void> set<T>(
    String key, 
    T value, {
    Duration? memoryExpiry,
    Duration? persistentExpiry,
  }) async {
    if (!_initialized) await init();
    
    final memDuration = memoryExpiry ?? const Duration(minutes: 30);
    final persistDuration = persistentExpiry ?? const Duration(hours: 24);

    // 1. Save to Memory
    _memoryCache[key] = CacheEntry<T>(
      value: value,
      expiryTime: DateTime.now().add(memDuration),
    );

    // 2. Save to Persistence
    // If it's a complex type (List/Map) that might be large, use File.
    // Otherwise use SharedPreferences.
    if (value is List || value is Map) {
      await _setInFile(key, value, expiry: persistDuration);
    } else {
      final entry = CacheEntry<T>(
        value: value,
        expiryTime: DateTime.now().add(persistDuration),
      );
      await _persistentCache.setString(key, jsonEncode(entry.toJson()));
    }
  }

  /// Generic REMOVE: Clears from all layers
  Future<void> remove(String key) async {
    if (!_initialized) await init();
    _memoryCache.remove(key);
    await _persistentCache.remove(key);
    await _removeFile(key);
    await _storage.delete(key: key);
  }

  // ==========================================
  // FILE OPERATIONS (Internal Helpers)
  // ==========================================

  Future<void> _setInFile(String key, dynamic data, {Duration expiry = const Duration(days: 7)}) async {
    if (_fileCacheDir == null) return;
    try {
      final file = File('${_fileCacheDir!.path}/$key.cache.json');
      final entry = {
        'data': data,
        'version': _version,
        'expiry': DateTime.now().add(expiry).toIso8601String(),
      };
      await file.writeAsString(jsonEncode(entry));
    } catch (e) {
      debugPrint('[CacheManager] File write error for $key: $e');
    }
  }

  Future<T?> _getFromFile<T>(String key) async {
    if (_fileCacheDir == null) return null;
    try {
      final file = File('${_fileCacheDir!.path}/$key.cache.json');
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final expiry = DateTime.tryParse(json['expiry'] ?? '');
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        await file.delete();
        return null;
      }

      // Check Version (Optional, can be strict or loose)
      if (json['version'] != _version) {
        await file.delete();
        return null;
      }

      // Cast data back to T
      return json['data'] as T?;
    } catch (e) {
      return null;
    }
  }

  Future<void> _removeFile(String key) async {
    if (_fileCacheDir == null) return;
    final file = File('${_fileCacheDir!.path}/$key.cache.json');
    if (await file.exists()) await file.delete();
  }

  // ==========================================
  // SECURE STORAGE (Public API)
  // ==========================================

  Future<String?> getFromSecure(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> setInSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // ==========================================
  // MAINTENANCE
  // ==========================================

  Future<void> clearAll() async {
    _memoryCache.clear();
    if (_initialized) {
      await _persistentCache.clear();
      await _storage.deleteAll();
      
      // Clear cache files
      if (_fileCacheDir != null) {
        try {
          _fileCacheDir!.listSync().where((fs) => fs.path.endsWith('.cache.json')).forEach((fs) {
            fs.deleteSync();
          });
        } catch (e) {
          debugPrint('[CacheManager] Error clearing file cache: $e');
        }
      }
    }
  }
}

/// Helper class for cache entries
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
    T typedValue;
    
    // Basic type restoration
    if (T == String) {
      typedValue = value.toString() as T;
    } else if (T == int) {
      typedValue = (value is num ? value.toInt() : int.parse(value.toString())) as T;
    } else if (T == double) {
      typedValue = (value is num ? value.toDouble() : double.parse(value.toString())) as T;
    } else if (T == bool) {
      typedValue = (value is bool ? value : value.toString() == 'true') as T;
    } else {
      // Complex types (Map/List) are handled by generic cast
      typedValue = value as T;
    }

    return CacheEntry(
      value: typedValue,
      expiryTime: DateTime.parse(json['expiryTime'] as String),
    );
  }
}