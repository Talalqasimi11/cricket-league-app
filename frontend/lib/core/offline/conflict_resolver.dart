import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/offline/sync_queue.dart';
import 'package:hive/hive.dart';

enum ConflictStrategy { serverWins, clientWins, manualMerge, lastWriteWins }

enum ConflictType {
  versionMismatch('Version mismatch - data modified on both sides'),
  concurrentEdit('Concurrent edit detected'),
  deletedServer('Item deleted on server'),
  deletedClient('Item deleted locally'),
  networkError('Network error during sync');

  const ConflictType(this.description);
  final String description;
}

class SyncConflict {
  final String id;
  final String operationId;
  final ConflictType type;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final DateTime localTimestamp;
  final DateTime serverTimestamp;
  final ConflictStrategy strategy;
  final String collection;
  final String itemId;

  SyncConflict({
    required this.id,
    required this.operationId,
    required this.type,
    required this.localData,
    required this.serverData,
    required this.localTimestamp,
    required this.serverTimestamp,
    this.strategy = ConflictStrategy.manualMerge,
    required this.collection,
    required this.itemId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'operationId': operationId,
    'type': type.name,
    'localData': localData,
    'serverData': serverData,
    'localTimestamp': localTimestamp.toIso8601String(),
    'serverTimestamp': serverTimestamp.toIso8601String(),
    'strategy': strategy.name,
    'collection': collection,
    'itemId': itemId,
  };

  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
    id: json['id'],
    operationId: json['operationId'],
    type: ConflictType.values.firstWhere((e) => e.name == json['type']),
    localData: Map<String, dynamic>.from(json['localData']),
    serverData: Map<String, dynamic>.from(json['serverData']),
    localTimestamp: DateTime.parse(json['localTimestamp']),
    serverTimestamp: DateTime.parse(json['serverTimestamp']),
    strategy: ConflictStrategy.values.firstWhere((e) => e.name == json['strategy']),
    collection: json['collection'],
    itemId: json['itemId'],
  );

  @override
  String toString() => 'SyncConflict(id: $id, type: $type, collection: $collection, itemId: $itemId)';
}

class ConflictResolution {
  final SyncConflict conflict;
  final Map<String, dynamic> resolvedData;
  final ConflictStrategy appliedStrategy;
  final bool keepClientVersion;
  final bool keepServerVersion;
  final DateTime resolutionTimestamp;

  ConflictResolution({
    required this.conflict,
    required this.resolvedData,
    required this.appliedStrategy,
    this.keepClientVersion = false,
    this.keepServerVersion = false,
  }) : resolutionTimestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
    'conflict': conflict.toJson(),
    'resolvedData': resolvedData,
    'appliedStrategy': appliedStrategy.name,
    'keepClientVersion': keepClientVersion,
    'keepServerVersion': keepServerVersion,
    'resolutionTimestamp': resolutionTimestamp.toIso8601String(),
  };
}

class ConflictResolver {
  static const String conflictsBoxName = 'sync_conflicts';
  static const String resolutionsBoxName = 'conflict_resolutions';

  late Box<Map> _conflictsBox;
  late Box<Map> _resolutionsBox;

  final StreamController<List<SyncConflict>> _conflictsController = StreamController.broadcast();
  final StreamController<ConflictResolution> _resolutionController = StreamController.broadcast();

  Stream<List<SyncConflict>> get conflicts => _conflictsController.stream;
  Stream<ConflictResolution> get resolutions => _resolutionController.stream;

  static final ConflictResolver instance = ConflictResolver._();

  ConflictResolver._();

  Future<void> init() async {
    _conflictsBox = await Hive.openBox<Map>(conflictsBoxName);
    _resolutionsBox = await Hive.openBox<Map>(resolutionsBoxName);
    debugPrint('ConflictResolver initialized');
  }

  // Detect conflicts during sync operations
  Future<bool> detectConflict({
    required String operationId,
    required String collection,
    required String itemId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required DateTime localTimestamp,
    required DateTime serverTimestamp,
  }) async {
    final ConflictType conflictType = _determineConflictType(localData, serverData, localTimestamp, serverTimestamp);

    if (conflictType != ConflictType.networkError) {
      final conflict = SyncConflict(
        id: '${collection}_${itemId}_${DateTime.now().millisecondsSinceEpoch}',
        operationId: operationId,
        type: conflictType,
        localData: localData,
        serverData: serverData,
        localTimestamp: localTimestamp,
        serverTimestamp: serverTimestamp,
        strategy: ConflictStrategy.manualMerge,
        collection: collection,
        itemId: itemId,
      );

      await _storeConflict(conflict);
      _conflictsController.add(await getAllConflicts());

      debugPrint('Conflict detected: ${conflict.toString()}');
      return true;
    }

    return false;
  }

  ConflictType _determineConflictType(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    DateTime localTimestamp,
    DateTime serverTimestamp
  ) {
    final bool localDeleted = localData['_deleted'] == true;
    final bool serverDeleted = serverData['_deleted'] == true;

    if (localDeleted && serverDeleted) {
      return ConflictType.concurrentEdit; // Both marked as deleted
    } else if (localDeleted && !serverDeleted) {
      return ConflictType.deletedClient;
    } else if (!localDeleted && serverDeleted) {
      return ConflictType.deletedServer;
    } else {
      // Compare timestamps or versions
      final localVersion = localData['_version'] ?? localTimestamp.millisecondsSinceEpoch;
      final serverVersion = serverData['_version'] ?? serverTimestamp.millisecondsSinceEpoch;

      if (localVersion != serverVersion) {
        return ConflictType.versionMismatch;
      }

      // Check if data was actually modified
      final localCopy = Map<String, dynamic>.from(localData);
      final serverCopy = Map<String, dynamic>.from(serverData);

      // Remove metadata fields for comparison
      const metadataFields = ['_version', '_timestamp', '_created', '_modified', 'id'];
      for (var field in metadataFields) {
        localCopy.remove(field);
        serverCopy.remove(field);
      }

      if (!mapEquals(localCopy, serverCopy)) {
        return ConflictType.concurrentEdit;
      }
    }

    return ConflictType.networkError;
  }

  // Auto-resolve conflicts based on strategies
  Future<ConflictResolution?> autoResolve(SyncConflict conflict) async {
    final strategy = conflict.strategy;
    Map<String, dynamic> resolvedData;
    bool keepClient = false;
    bool keepServer = false;

    switch (strategy) {
      case ConflictStrategy.serverWins:
        resolvedData = conflict.serverData;
        keepClient = false;
        keepServer = true;
        break;

      case ConflictStrategy.clientWins:
        resolvedData = conflict.localData;
        keepClient = true;
        keepServer = false;
        break;

      case ConflictStrategy.lastWriteWins:
        resolvedData = conflict.localTimestamp.isAfter(conflict.serverTimestamp)
            ? conflict.localData
            : conflict.serverData;
        keepClient = conflict.localTimestamp.isAfter(conflict.serverTimestamp);
        keepServer = !keepClient;
        break;

      case ConflictStrategy.manualMerge:
      // Cannot auto-resolve, requires manual intervention
        return null;
    }

    // Apply metadata to resolved data
    resolvedData = {
      ...resolvedData,
      '_version': (conflict.localData['_version'] ?? 0) + (conflict.serverData['_version'] ?? 0) + 1,
      '_conflictResolved': DateTime.now().toIso8601String(),
      '_resolutionStrategy': strategy.name,
    };

    final resolution = ConflictResolution(
      conflict: conflict,
      resolvedData: resolvedData,
      appliedStrategy: strategy,
      keepClientVersion: keepClient,
      keepServerVersion: keepServer,
    );

    await _storeResolution(resolution);
    await _removeConflict(conflict.id);

    await SyncQueue.instance.notifyConflictResolved(conflict.operationId, resolution);

    _resolutionController.add(resolution);
    _conflictsController.add(await getAllConflicts());

    debugPrint('Auto-resolved conflict: ${conflict.id} using ${strategy.name}');
    return resolution;
  }

  // Manual resolution by user
  Future<ConflictResolution> resolveManually(
    SyncConflict conflict,
    Map<String, dynamic> resolvedData,
    {bool keepClient = false, bool keepServer = false}
  ) async {
    final resolution = ConflictResolution(
      conflict: conflict,
      resolvedData: resolvedData,
      appliedStrategy: ConflictStrategy.manualMerge,
      keepClientVersion: keepClient,
      keepServerVersion: keepServer,
    );

    await _storeResolution(resolution);
    await _removeConflict(conflict.id);

    await SyncQueue.instance.notifyConflictResolved(conflict.operationId, resolution);

    _resolutionController.add(resolution);
    _conflictsController.add(await getAllConflicts());

    debugPrint('Manually resolved conflict: ${conflict.id}');
    return resolution;
  }

  // Get all pending conflicts
  Future<List<SyncConflict>> getAllConflicts() async {
    final conflicts = <SyncConflict>[];

    for (final key in _conflictsBox.keys) {
      final data = _conflictsBox.get(key);
      if (data != null) {
        conflicts.add(SyncConflict.fromJson(Map<String, dynamic>.from(data)));
      }
    }

    return conflicts;
  }

  // Get conflicts for specific collection/item
  Future<List<SyncConflict>> getConflictsForItem(String collection, String itemId) async {
    final allConflicts = await getAllConflicts();
    return allConflicts.where((c) => c.collection == collection && c.itemId == itemId).toList();
  }

  // Get resolution history
  Future<List<ConflictResolution>> getResolutionHistory({int limit = 50}) async {
    final resolutions = <ConflictResolution>[];

    final keys = _resolutionsBox.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    for (final key in keys.take(limit)) {
      final data = _resolutionsBox.get(key);
      if (data != null) {
        try {
          final jsonData = Map<String, dynamic>.from(data);
          final conflict = SyncConflict.fromJson(jsonData['conflict']);
          resolutions.add(ConflictResolution(
            conflict: conflict,
            resolvedData: Map<String, dynamic>.from(jsonData['resolvedData']),
            appliedStrategy: ConflictStrategy.values.firstWhere((e) => e.name == jsonData['appliedStrategy']),
            keepClientVersion: jsonData['keepClientVersion'] ?? false,
            keepServerVersion: jsonData['keepServerVersion'] ?? false,
          ));
        } catch (e) {
          debugPrint('Error parsing resolution: $e');
        }
      }
    }

    return resolutions;
  }

  Future<void> _storeConflict(SyncConflict conflict) async {
    await _conflictsBox.put(conflict.id, conflict.toJson());
  }

  Future<void> _removeConflict(String conflictId) async {
    await _conflictsBox.delete(conflictId);
  }

  Future<void> _storeResolution(ConflictResolution resolution) async {
    final key = '${resolution.conflict.collection}_${resolution.conflict.itemId}_${DateTime.now().millisecondsSinceEpoch}';
    await _resolutionsBox.put(key, resolution.toJson());

    // Keep only last 100 resolutions to prevent box from growing too large
    if (_resolutionsBox.length > 100) {
      final keys = _resolutionsBox.keys.toList()..sort();
      final toDelete = keys.take(_resolutionsBox.length - 100);
      for (final key in toDelete) {
        await _resolutionsBox.delete(key);
      }
    }
  }

  // Clear all conflicts (useful for testing or emergency reset)
  Future<void> clearAllConflicts() async {
    await _conflictsBox.clear();
    _conflictsController.add([]);
  }

  // Set default conflict resolution strategy for a collection
  final Map<String, ConflictStrategy> _defaultStrategies = {
    'teams': ConflictStrategy.lastWriteWins,
    'players': ConflictStrategy.manualMerge,
    'tournaments': ConflictStrategy.serverWins,
    'matches': ConflictStrategy.serverWins,
    'scores': ConflictStrategy.serverWins, // Safety first
  };

  ConflictStrategy getDefaultStrategy(String collection) {
    return _defaultStrategies[collection] ?? ConflictStrategy.manualMerge;
  }

  void setDefaultStrategy(String collection, ConflictStrategy strategy) {
    _defaultStrategies[collection] = strategy;
  }

  // Cleanup old resolutions (keep last 30 days)
  Future<void> cleanupOldResolutions() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final keysToDelete = <dynamic>[];

    for (final key in _resolutionsBox.keys) {
      final data = _resolutionsBox.get(key);
      if (data != null) {
        try {
          final resolutionTimestamp = DateTime.parse(data['resolutionTimestamp']);
          if (resolutionTimestamp.isBefore(cutoff)) {
            keysToDelete.add(key);
          }
        } catch (e) {
          // Invalid data, mark for deletion
          keysToDelete.add(key);
        }
      }
    }

    for (final key in keysToDelete) {
      await _resolutionsBox.delete(key);
    }

    if (keysToDelete.isNotEmpty) {
      debugPrint('Cleaned up ${keysToDelete.length} old conflict resolutions');
    }
  }

  void dispose() {
    _conflictsController.close();
    _resolutionController.close();
    _conflictsBox.close();
    _resolutionsBox.close();
  }
}

// Smart field-level merger for manual resolution
class ConflictMerger {
  static Map<String, dynamic> merge(
    Map<String, dynamic> local,
    Map<String, dynamic> server, {
    List<String>? priorityFields,
  }) {
    final merged = <String, dynamic>{};
    final allKeys = {...local.keys, ...server.keys};

    final clientPriority = priorityFields ?? [];

    for (final key in allKeys) {
      final localValue = local[key];
      final serverValue = server[key];

      if (localValue == null && serverValue != null) {
        merged[key] = serverValue;
      } else if (localValue != null && serverValue == null) {
        merged[key] = localValue;
      } else if (clientPriority.contains(key)) {
        // Client priority fields
        merged[key] = localValue;
      } else if (_isSimpleValue(localValue) && _isSimpleValue(serverValue)) {
        // For simple values, use local if it's newer
        merged[key] = localValue;
      } else if (localValue is List && serverValue is List) {
        // Merge arrays (keep unique items, prefer local order)
        merged[key] = _mergeArrays(localValue, serverValue);
      } else {
        // Keep local version by default
        merged[key] = localValue;
      }
    }

    return merged;
  }

  static bool _isSimpleValue(dynamic value) {
    return value is String || value is num || value is bool;
  }

  static List<dynamic> _mergeArrays(List<dynamic> local, List<dynamic> server) {
    final merged = <dynamic>[];
    final seen = <dynamic>{};

    // Add local items first
    for (final item in local) {
      if (!seen.contains(item)) {
        merged.add(item);
        seen.add(item);
      }
    }

    // Add server items that aren't already present
    for (final item in server) {
      if (!seen.contains(item)) {
        merged.add(item);
        seen.add(item);
      }
    }

    return merged;
  }

  // Calculate merge confidence (0.0 to 1.0)
  static double calculateMergeConfidence(
    Map<String, dynamic> local,
    Map<String, dynamic> server
  ) {
    if (local.isEmpty && server.isEmpty) return 1.0;
    if (local.isEmpty || server.isEmpty) return 0.5;

    double matchingFields = 0;
    final totalFields = {...local.keys, ...server.keys}.length;

    for (final key in local.keys) {
      if (server.containsKey(key)) {
        final localVal = local[key];
        final serverVal = server[key];

        if (localVal == serverVal) {
          matchingFields += 1.0;
        } else if (_isSimpleValue(localVal) && _isSimpleValue(serverVal)) {
          // Close enough for simple values
          matchingFields += 0.5;
        }
      }
    }

    return totalFields > 0 ? matchingFields / totalFields : 0.0;
  }
}
