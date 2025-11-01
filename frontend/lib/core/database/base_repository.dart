import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'hive_service.dart';

/// Base repository class providing common CRUD operations for all entities
abstract class BaseRepository<T extends HiveObject> {
  final HiveService _hiveService;
  final String _boxName;

  BaseRepository(this._hiveService, this._boxName);

  Box get _box => _hiveService.getBox(_boxName);

  /// Get entity by ID
  T? getById(int id) {
    try {
      return _box.get(id) as T?;
    } catch (e) {
      debugPrint('[$_boxName] Error getting entity by ID $id: $e');
      return null;
    }
  }

  /// Get all entities
  List<T> getAll() {
    try {
      return _box.values.cast<T>().toList();
    } catch (e) {
      debugPrint('[$_boxName] Error getting all entities: $e');
      return [];
    }
  }

  /// Get entity by key (string or int)
  T? getByKey(dynamic key) {
    try {
      return _box.get(key) as T?;
    } catch (e) {
      debugPrint('[$_boxName] Error getting entity by key $key: $e');
      return null;
    }
  }

  /// Save entity - returns the key it was saved under
  Future<dynamic> save(T entity) async {
    try {
      final key = await _box.add(entity);
      debugPrint('[$_boxName] Entity saved with key: $key');
      return key;
    } catch (e) {
      debugPrint('[$_boxName] Error saving entity: $e');
      rethrow;
    }
  }

  /// Save entity with specific key
  Future<void> saveWithKey(dynamic key, T entity) async {
    try {
      await _box.put(key, entity);
      debugPrint('[$_boxName] Entity saved with key: $key');
    } catch (e) {
      debugPrint('[$_boxName] Error saving entity with key $key: $e');
      rethrow;
    }
  }

  /// Update existing entity
  Future<void> update(dynamic key, T entity) async {
    try {
      await _box.put(key, entity);
      debugPrint('[$_boxName] Entity updated with key: $key');
    } catch (e) {
      debugPrint('[$_boxName] Error updating entity with key $key: $e');
      rethrow;
    }
  }

  /// Delete entity by key
  Future<void> delete(dynamic key) async {
    try {
      await _box.delete(key);
      debugPrint('[$_boxName] Entity deleted with key: $key');
    } catch (e) {
      debugPrint('[$_boxName] Error deleting entity with key $key: $e');
      rethrow;
    }
  }

  /// Delete multiple entities by keys
  Future<void> deleteMultiple(List<dynamic> keys) async {
    try {
      await _box.deleteAll(keys);
      debugPrint('[$_boxName] ${keys.length} entities deleted');
    } catch (e) {
      debugPrint('[$_boxName] Error deleting multiple entities: $e');
      rethrow;
    }
  }

  /// Clear all entities in the box
  Future<void> clearAll() async {
    try {
      await _box.clear();
      debugPrint('[$_boxName] All entities cleared');
    } catch (e) {
      debugPrint('[$_boxName] Error clearing all entities: $e');
      rethrow;
    }
  }

  /// Get count of entities
  int get count => _box.length;

  /// Check if entity exists by key
  bool containsKey(dynamic key) {
    return _box.containsKey(key);
  }

  /// Get all keys
  Iterable get keys => _box.keys;

  /// Listen to box changes
  Stream<BoxEvent> watch() => _box.watch();

  /// Filter entities by predicate
  List<T> filter(bool Function(T) predicate) {
    try {
      return _box.values.cast<T>().where(predicate).toList();
    } catch (e) {
      debugPrint('[$_boxName] Error filtering entities: $e');
      return [];
    }
  }

  /// Find first entity matching predicate
  T? findFirst(bool Function(T) predicate) {
    try {
      return _box.values.cast<T>().cast<T?>().firstWhere(
            (entity) => entity != null && predicate(entity),
            orElse: () => null,
          );
    } catch (e) {
      debugPrint('[$_boxName] Error finding first entity: $e');
      return null;
    }
  }
}
