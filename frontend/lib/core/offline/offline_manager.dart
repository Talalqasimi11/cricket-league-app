import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/hive_service.dart';
import '../../models/pending_operation.dart';
import '../../services/api_service.dart';
import '../network_manager.dart';

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  serverWins, // Server data takes precedence
  clientWins, // Local data takes precedence
  manual, // User decides which version to keep
  merge, // Attempt to merge conflicting data
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int operationsProcessed;
  final int operationsFailed;
  final List<String> errors;
  final Duration duration;

  SyncResult({
    required this.success,
    required this.operationsProcessed,
    required this.operationsFailed,
    required this.errors,
    required this.duration,
  });
}

/// Manages offline operations, sync coordination, and conflict resolution
class OfflineManager {
  final HiveService _hiveService;
  final ApiService _apiService;

  StreamSubscription<bool>? _networkSubscription;

  Timer? _syncTimer;
  bool _isOnline = false;
  bool _isInitialized = false;
  bool _isSyncing = false;

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
  }) : _hiveService = hiveService,
       _apiService = apiService;

  /// Initialize the offline manager
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _isOnline = NetworkManager.instance.hasConnection;
      _updateOnlineStatus(_isOnline);

      _networkSubscription = NetworkManager.instance.onConnectionChanged.listen(
        _updateOnlineStatus,
      );

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
    await _networkSubscription?.cancel();
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

  /// Update online status based on NetworkManager updates
  void _updateOnlineStatus(bool isConnected) {
    final wasOnline = _isOnline;
    _isOnline = isConnected;

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
  Stream<int> get pendingOperationsCount => _pendingOperationsController.stream;

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
      // Reject unsupported operations
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
      return SyncResult(
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
    if (_isSyncing) {
      debugPrint('[OfflineManager] Sync already in progress, skipping.');
      return SyncResult(
        success: true,
        operationsProcessed: 0,
        operationsFailed: 0,
        errors: [],
        duration: Duration.zero,
      );
    }
    _isSyncing = true;

    final startTime = DateTime.now();
    int processed = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      debugPrint('[OfflineManager] Starting sync operation');

      final operations = getPendingOperations();
      if (operations.isEmpty) {
        debugPrint('[OfflineManager] No pending operations to sync');
        return SyncResult(
          success: true,
          operationsProcessed: 0,
          operationsFailed: 0,
          errors: [],
          duration: DateTime.now().difference(startTime),
        );
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
              final updatedOperation = operation.markAttempted();
              await box.put(operation.key, updatedOperation);
            } else {
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
      return SyncResult(
        success: false,
        operationsProcessed: processed,
        operationsFailed: failed + 1,
        errors: [...errors, e.toString()],
        duration: DateTime.now().difference(startTime),
      );
    } finally {
      _isSyncing = false;
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

  Future<bool> _syncPlayer(PendingOperation operation) async {
    debugPrint(
      '[OfflineManager] Player operations are intentionally unsupported for offline queuing',
    );
    return false;
  }

  // ===== CONFLICT RESOLUTION =====

  Future<void> resolveConflict({
    required PendingOperation operation,
    required ConflictResolutionStrategy strategy,
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
          await _executeOperation(operation);
          break;
        case ConflictResolutionStrategy.manual:
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
