import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../database/hive_service.dart';
import '../../models/pending_operation.dart';
import '../../services/api_service.dart';

// =====================================================
// SyncResult model (used by OfflineManager)
// =====================================================
class SyncResult {
  final bool success;
  final int operationsProcessed;
  final int operationsFailed;
  final List<String> errors;
  final Duration duration;

  const SyncResult({
    required this.success,
    required this.operationsProcessed,
    required this.operationsFailed,
    required this.errors,
    required this.duration,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, '
        'processed: $operationsProcessed, '
        'failed: $operationsFailed, '
        'duration: ${duration.inMilliseconds}ms, '
        'errors: $errors)';
  }
}

// =====================================================
// Back-compat enum for older conflict resolution paths
// still using ConflictResolutionStrategy
// =====================================================
enum ConflictResolutionStrategy {
  serverWins,
  clientWins,
  manual,
  merge,
  lastWriteWins,
}

/// Conflict resolution strategies (newer, used by ConflictResolver)
enum ConflictStrategy {
  serverWins, // Server data takes precedence
  clientWins, // Local data takes precedence
  manualMerge, // User decides which version to keep
  lastWriteWins, // Use timestamp/version to decide
}

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
        strategy: ConflictStrategy.values
            .firstWhere((e) => e.name == json['strategy']),
        collection: json['collection'],
        itemId: json['itemId'],
      );

  @override
  String toString() =>
      'SyncConflict(id: $id, type: $type, collection: $collection, itemId: $itemId)';
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

// =====================================================
// Listener interface to avoid circular imports
// =====================================================
abstract class ConflictResolutionListener {
  Future<void> onConflictResolved(
    String operationId,
    ConflictResolution resolution,
  );
}

class ConflictResolver {
  static const String conflictsBoxName = 'sync_conflicts';
  static const String resolutionsBoxName = 'conflict_resolutions';

  // Optional listener (e.g., SyncQueue) for resolution notifications
  static ConflictResolutionListener? resolutionListener;
  static void setResolutionListener(ConflictResolutionListener? listener) {
    resolutionListener = listener;
  }

  late Box<Map> _conflictsBox;
  late Box<Map> _resolutionsBox;

  final StreamController<List<SyncConflict>> _conflictsController =
      StreamController<List<SyncConflict>>.broadcast();
  final StreamController<ConflictResolution> _resolutionController =
      StreamController<ConflictResolution>.broadcast();

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
    final ConflictType conflictType = _determineConflictType(
      localData,
      serverData,
      localTimestamp,
      serverTimestamp,
    );

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
    DateTime serverTimestamp,
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
      final localVersion =
          localData['_version'] ?? localTimestamp.millisecondsSinceEpoch;
      final serverVersion =
          serverData['_version'] ?? serverTimestamp.millisecondsSinceEpoch;

      if (localVersion != serverVersion) {
        return ConflictType.versionMismatch;
      }

      // Check if data was actually modified
      final localCopy = Map<String, dynamic>.from(localData);
      final serverCopy = Map<String, dynamic>.from(serverData);

      // Remove metadata fields for comparison
      const metadataFields = [
        '_version',
        '_timestamp',
        '_created',
        '_modified',
        'id'
      ];
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
        final clientNewer =
            conflict.localTimestamp.isAfter(conflict.serverTimestamp);
        resolvedData = clientNewer ? conflict.localData : conflict.serverData;
        keepClient = clientNewer;
        keepServer = !clientNewer;
        break;

      case ConflictStrategy.manualMerge:
        // Cannot auto-resolve, requires manual intervention
        return null;
    }

    // Apply metadata to resolved data (use next version = max(local, server) + 1)
    final int localVersion = (conflict.localData['_version'] as int?) ?? 0;
    final int serverVersion = (conflict.serverData['_version'] as int?) ?? 0;
    final int nextVersion =
        (localVersion > serverVersion ? localVersion : serverVersion) + 1;

    resolvedData = {
      ...resolvedData,
      '_version': nextVersion,
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

    // Notify listener (e.g., SyncQueue) if present
    try {
      await ConflictResolver.resolutionListener
          ?.onConflictResolved(conflict.operationId, resolution);
    } catch (e) {
      debugPrint('[ConflictResolver] Listener error: $e');
    }

    _resolutionController.add(resolution);
    _conflictsController.add(await getAllConflicts());

    debugPrint('Auto-resolved conflict: ${conflict.id} using ${strategy.name}');
    return resolution;
  }

  // Manual resolution by user
  Future<ConflictResolution> resolveManually(
    SyncConflict conflict,
    Map<String, dynamic> resolvedData, {
    bool keepClient = false,
    bool keepServer = false,
  }) async {
    final resolution = ConflictResolution(
      conflict: conflict,
      resolvedData: resolvedData,
      appliedStrategy: ConflictStrategy.manualMerge,
      keepClientVersion: keepClient,
      keepServerVersion: keepServer,
    );

    await _storeResolution(resolution);
    await _removeConflict(conflict.id);

    // Notify listener (e.g., SyncQueue) if present
    try {
      await ConflictResolver.resolutionListener
          ?.onConflictResolved(conflict.operationId, resolution);
    } catch (e) {
      debugPrint('[ConflictResolver] Listener error: $e');
    }

    _resolutionController.add(resolution);
    _conflictsController.add(await getAllConflicts());

    debugPrint('Manually resolved conflict: ${conflict.id}');
    return resolution;
  }

  // Get all pending conflicts
  Future<List<SyncConflict>> getAllConflicts() async {
    final conflicts = <SyncConflict>[];

    // Box<Map> guarantees values are Map. No need for an extra type check.
    for (final value in _conflictsBox.values) {
      conflicts.add(
        SyncConflict.fromJson(Map<String, dynamic>.from(value)),
      );
    }

    return conflicts;
  }

  // Get conflicts for specific collection/item
  Future<List<SyncConflict>> getConflictsForItem(
    String collection,
    String itemId,
  ) async {
    final allConflicts = await getAllConflicts();
    return allConflicts
        .where((c) => c.collection == collection && c.itemId == itemId)
        .toList();
  }

  // Get resolution history
  Future<List<ConflictResolution>> getResolutionHistory({int limit = 50}) async {
    final resolutions = <ConflictResolution>[];

    final List<String> keys =
        _resolutionsBox.keys.cast<String>().toList()
          ..sort((a, b) => b.compareTo(a)); // Most recent first

    for (final key in keys.take(limit)) {
      final data = _resolutionsBox.get(key);
      if (data != null) {
        try {
          final jsonData = Map<String, dynamic>.from(data);
          final conflict = SyncConflict.fromJson(
            Map<String, dynamic>.from(jsonData['conflict']),
          );
          resolutions.add(
            ConflictResolution(
              conflict: conflict,
              resolvedData: Map<String, dynamic>.from(jsonData['resolvedData']),
              appliedStrategy: ConflictStrategy.values.firstWhere(
                  (e) => e.name == jsonData['appliedStrategy']),
              keepClientVersion: jsonData['keepClientVersion'] ?? false,
              keepServerVersion: jsonData['keepServerVersion'] ?? false,
            ),
          );
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
    final key =
        '${resolution.conflict.collection}_${resolution.conflict.itemId}_${DateTime.now().millisecondsSinceEpoch}';
    await _resolutionsBox.put(key, resolution.toJson());

    // Keep only last 100 resolutions to prevent box from growing too large
    if (_resolutionsBox.length > 100) {
      final keys = _resolutionsBox.keys.cast<String>().toList()..sort();
      final toDelete = keys.take(_resolutionsBox.length - 100);
      for (final k in toDelete) {
        await _resolutionsBox.delete(k);
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
    final keysToDelete = <String>[];

    for (final key in _resolutionsBox.keys.cast<String>()) {
      final data = _resolutionsBox.get(key);
      if (data != null) {
        try {
          final resolutionTimestamp =
              DateTime.parse(data['resolutionTimestamp']);
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

  Future<void> dispose() async {
    await _conflictsController.close();
    await _resolutionController.close();
    await _conflictsBox.close();
    await _resolutionsBox.close();
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

    final clientPriority = priorityFields ?? <String>[];

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
        // For simple values, use local by default (caller can choose a strategy)
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
    Map<String, dynamic> server,
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

/// Offline Manager — manages operations, connectivity, and sync
class OfflineManager {
  final HiveService _hiveService;
  final ApiService _apiService;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isOnline = false;
  bool _isInitialized = false;

  // Sync configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 30);

  // Streams for UI updates
  final StreamController<bool> _onlineStatusController =
      StreamController<bool>.broadcast();
  final StreamController<SyncResult> _syncResultController =
      StreamController<SyncResult>.broadcast();
  final StreamController<int> _pendingOperationsController =
      StreamController<int>.broadcast();

  OfflineManager({
    required HiveService hiveService,
    required ApiService apiService,
  })  : _hiveService = hiveService,
        _apiService = apiService,
        _connectivity = Connectivity();

  /// Initialize the offline manager
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Check initial connectivity
      final connectivityResults = await _connectivity.checkConnectivity();
      _updateOnlineStatus(connectivityResults);

      // Listen to connectivity changes
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(_updateOnlineStatus);

      // Start periodic sync
      _startPeriodicSync();

      _isInitialized = true;
      debugPrint('[OfflineManager] Initialized successfully');
    } catch (e) {
      debugPrint('[OfflineManager] Initialization failed: $e');
      rethrow;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    await _onlineStatusController.close();
    await _syncResultController.close();
    await _pendingOperationsController.close();
    debugPrint('[OfflineManager] Disposed');
  }

  // ===== CONNECTIVITY MANAGEMENT =====

  /// Stream of online status changes
  Stream<bool> get onlineStatus => _onlineStatusController.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Update online status based on connectivity
  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    // Consider online if any connection type is available (not none)
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    if (_isOnline != wasOnline) {
      _onlineStatusController.add(_isOnline);
      debugPrint('[OfflineManager] Online status changed: $_isOnline');

      if (_isOnline && !wasOnline) {
        // Just came online, trigger sync
        _performSync();
      }
    }
  }

  // ===== OPERATION QUEUING =====

  /// Stream of pending operations count changes
  Stream<int> get pendingOperationsCount =>
      _pendingOperationsController.stream;

  /// Get current pending operations count
  int getPendingOperationsCount() {
    try {
      return _hiveService.getBox(HiveService.boxPendingOperations).length;
    } catch (e) {
      debugPrint('[OfflineManager] Error getting pending operations count: $e');
      return 0;
    }
  }

  /// Queue an operation for offline sync
  Future<void> queueOperation({
    required OperationType operationType,
    required String entityType,
    required int entityId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Reject unsupported operations at queuing time to prevent permanent sync failures
      if (entityType == 'player') {
        throw UnsupportedError(
          'Player operations are not supported for offline queuing',
        );
      }

      final operation = PendingOperation.create(
        operationType: operationType,
        entityType: entityType,
        entityId: entityId,
        data: data,
      );

      final box = _hiveService.getBox(HiveService.boxPendingOperations);
      await box.add(operation);

      _pendingOperationsController.add(box.length);
      debugPrint('[OfflineManager] Queued operation: ${operation.description}');

      // If online, try to sync immediately
      if (_isOnline) {
        _performSync();
      }
    } catch (e) {
      debugPrint('[OfflineManager] Error queuing operation: $e');
      rethrow;
    }
  }

  /// Get all pending operations sorted by priority
  List<PendingOperation> getPendingOperations() {
    try {
      final box = _hiveService.getBox(HiveService.boxPendingOperations);
      final operations = box.values.cast<PendingOperation>().toList();

      // Sort by priority (lower number = higher priority)
      operations.sort((a, b) => a.priority.compareTo(b.priority));
      return operations;
    } catch (e) {
      debugPrint('[OfflineManager] Error getting pending operations: $e');
      return [];
    }
  }

  // ===== SYNC MANAGEMENT =====

  /// Stream of sync results
  Stream<SyncResult> get syncResults => _syncResultController.stream;

  /// Manually trigger a sync operation
  Future<SyncResult> syncNow() async {
    if (!_isOnline) {
      return const SyncResult(
        success: false,
        operationsProcessed: 0,
        operationsFailed: 0,
        errors: ['Device is offline'],
        duration: Duration.zero,
      );
    }

    return await _performSync();
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(syncInterval, (timer) {
      if (_isOnline) {
        _performSync();
      }
    });
  }

  /// Perform the actual sync operation
  Future<SyncResult> _performSync() async {
    final startTime = DateTime.now();
    int processed = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      debugPrint('[OfflineManager] Starting sync operation');

      final operations = getPendingOperations();
      if (operations.isEmpty) {
        debugPrint('[OfflineManager] No pending operations to sync');
        final duration = DateTime.now().difference(startTime);
        final result = SyncResult(
          success: true,
          operationsProcessed: 0,
          operationsFailed: 0,
          errors: const [],
          duration: duration,
        );
        _syncResultController.add(result);
        return result;
      }

      final box = _hiveService.getBox(HiveService.boxPendingOperations);

      for (final operation in operations) {
        try {
          final success = await _executeOperation(operation);
          if (success) {
            await box.delete(operation.key);
            processed++;
          } else {
            failed++;
            if (operation.shouldRetry(maxRetries: maxRetryAttempts)) {
              // Mark as attempted and keep in queue for retry
              final updatedOperation = operation.markAttempted();
              await box.put(operation.key, updatedOperation);
            } else {
              // Max retries reached, remove from queue
              await box.delete(operation.key);
              errors.add('Max retries reached for ${operation.description}');
            }
          }
        } catch (e) {
          failed++;
          errors.add('Error processing ${operation.description}: $e');
          debugPrint('[OfflineManager] Error processing operation: $e');
        }
      }

      _pendingOperationsController.add(box.length);

      final result = SyncResult(
        success: failed == 0,
        operationsProcessed: processed,
        operationsFailed: failed,
        errors: errors,
        duration: DateTime.now().difference(startTime),
      );

      _syncResultController.add(result);
      debugPrint(
        '[OfflineManager] Sync completed: $processed processed, $failed failed',
      );

      return result;
    } catch (e) {
      debugPrint('[OfflineManager] Sync failed: $e');
      final result = SyncResult(
        success: false,
        operationsProcessed: processed,
        operationsFailed: failed + 1,
        errors: [...errors, e.toString()],
        duration: DateTime.now().difference(startTime),
      );
      _syncResultController.add(result);
      return result;
    }
  }

  /// Execute a single pending operation
  Future<bool> _executeOperation(PendingOperation operation) async {
    try {
      switch (operation.entityType) {
        case 'tournament':
          return await _syncTournament(operation);
        case 'match':
          return await _syncMatch(operation);
        case 'team':
          return await _syncTeam(operation);
        case 'player':
          return await _syncPlayer(operation);
        default:
          debugPrint(
            '[OfflineManager] Unknown entity type: ${operation.entityType}',
          );
          return false;
      }
    } catch (e) {
      debugPrint(
        '[OfflineManager] Error executing operation ${operation.description}: $e',
      );
      return false;
    }
  }

  // ===== ENTITY SYNC METHODS =====

  Future<bool> _syncTournament(PendingOperation operation) async {
    try {
      switch (operation.operationType) {
        case OperationType.create:
          await _apiService.createTournament(operation.data);
          return true;

        case OperationType.update:
          // ApiService expects String IDs
          await _apiService.updateTournament(
            operation.entityId.toString(),
            operation.data,
          );
          return true;

        case OperationType.delete:
          debugPrint('[OfflineManager] Delete tournament not supported');
          return false;
      }
    } catch (e) {
      debugPrint('[OfflineManager] Tournament sync error: $e');
      return false;
    }
  }

  Future<bool> _syncMatch(PendingOperation operation) async {
    try {
      switch (operation.operationType) {
        case OperationType.create:
          await _apiService.createMatch(operation.data);
          return true;

        case OperationType.update:
          await _apiService.updateMatch(
            operation.entityId.toString(),
            operation.data,
          );
          return true;

        case OperationType.delete:
          debugPrint('[OfflineManager] Delete match not supported');
          return false;
      }
    } catch (e) {
      debugPrint('[OfflineManager] Match sync error: $e');
      return false;
    }
  }

  Future<bool> _syncTeam(PendingOperation operation) async {
    try {
      switch (operation.operationType) {
        case OperationType.create:
          await _apiService.createTeam(operation.data);
          return true;

        case OperationType.update:
          await _apiService.updateTeam(
            operation.entityId.toString(),
            operation.data,
          );
          return true;

        case OperationType.delete:
          debugPrint('[OfflineManager] Delete team not supported');
          return false;
      }
    } catch (e) {
      debugPrint('[OfflineManager] Team sync error: $e');
      return false;
    }
  }

  /// Sync player operations (intentionally unsupported)
  Future<bool> _syncPlayer(PendingOperation operation) async {
    debugPrint(
      '[OfflineManager] Player operations are intentionally unsupported for offline queuing',
    );
    return false;
  }

  // ===== CONFLICT RESOLUTION =====

  Future<void> resolveConflict({
    required PendingOperation operation,
    required ConflictResolutionStrategy strategy, // back-compat
    Map<String, dynamic>? mergedData,
  }) async {
    try {
      switch (strategy) {
        case ConflictResolutionStrategy.serverWins:
          await _hiveService
              .getBox(HiveService.boxPendingOperations)
              .delete(operation.key);
          break;

        case ConflictResolutionStrategy.clientWins:
        case ConflictResolutionStrategy.lastWriteWins:
          // For offline queue, lastWriteWins defaults to applying the client operation
          await _executeOperation(operation);
          break;

        case ConflictResolutionStrategy.manual:
          // Keep the operation for manual resolution
          break;

        case ConflictResolutionStrategy.merge:
          if (mergedData != null) {
            final mergedOperation = operation.copyWith(data: mergedData);
            await _hiveService
                .getBox(HiveService.boxPendingOperations)
                .put(operation.key, mergedOperation);
            await _executeOperation(mergedOperation);
          }
          break;
      }

      _pendingOperationsController.add(getPendingOperationsCount());
    } catch (e) {
      debugPrint('[OfflineManager] Error resolving conflict: $e');
    }
  }

  // ===== UTILITY METHODS =====

  Future<void> clearPendingOperations() async {
    try {
      await _hiveService.getBox(HiveService.boxPendingOperations).clear();
      _pendingOperationsController.add(0);
      debugPrint('[OfflineManager] Cleared all pending operations');
    } catch (e) {
      debugPrint('[OfflineManager] Error clearing pending operations: $e');
    }
  }

  Map<String, dynamic> getSyncStats() {
    final operations = getPendingOperations();
    final stats = <String, int>{};

    for (final op in operations) {
      final key = '${op.entityType}_${op.operationType.name}';
      stats[key] = (stats[key] ?? 0) + 1;
    }

    return {
      'totalPending': operations.length,
      'byType': stats,
      'isOnline': _isOnline,
      'lastSyncAttempt': operations.isNotEmpty
          ? operations
              .map((op) => op.lastAttempt)
              .where((date) => date != null)
              .fold<DateTime?>(
                null,
                (prev, curr) =>
                    prev == null || curr!.isAfter(prev) ? curr : prev,
              )
          : null,
    };
  }
}