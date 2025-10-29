import 'dart:async';
import '../caching/cache_manager.dart';
import '../api_client.dart';

/// Manages offline functionality and data synchronization
class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  static OfflineManager get instance => _instance;

  final _pendingOperations = <PendingOperation>[];
  final _syncController = StreamController<SyncStatus>.broadcast();
  bool _isSyncing = false;
  Timer? _syncTimer;

  OfflineManager._internal() {
    // Load any saved operations and start periodic sync
    _loadPendingOperations().then((_) => _startPeriodicSync());
  }

  // Stream of sync status updates
  Stream<SyncStatus> get syncStatus => _syncController.stream;

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncPendingOperations();
    });
  }

  // Queue an operation for later execution
  Future<void> queueOperation(PendingOperation operation) async {
    _pendingOperations.add(operation);
    await _savePendingOperations();
    _syncController.add(
      SyncStatus(pending: _pendingOperations.length, syncing: _isSyncing),
    );
  }

  // Save pending operations to persistent storage
  Future<void> _savePendingOperations() async {
    await CacheManager.instance.setInPersistent(
      'pending_operations',
      _pendingOperations.map((op) => op.toJson()).toList(),
    );
  }

  // Load pending operations from persistent storage
  Future<void> _loadPendingOperations() async {
    final ops = await CacheManager.instance.getFromPersistent<List>(
      'pending_operations',
    );
    if (ops != null) {
      _pendingOperations.clear();
      _pendingOperations.addAll(
        ops.map((op) => PendingOperation.fromJson(op as Map<String, dynamic>)),
      );
    }
  }

  // Sync all pending operations
  Future<void> syncPendingOperations() async {
    if (_isSyncing || _pendingOperations.isEmpty) return;

    _isSyncing = true;
    _syncController.add(
      SyncStatus(pending: _pendingOperations.length, syncing: true),
    );

    try {
      while (_pendingOperations.isNotEmpty) {
        final operation = _pendingOperations.first;
        try {
          await operation.execute();
          _pendingOperations.removeAt(0);
          await _savePendingOperations();
        } catch (e) {
          if (operation.retryCount >= operation.maxRetries) {
            _pendingOperations.removeAt(0);
            await _savePendingOperations();
          } else {
            operation.retryCount++;
            // Move to end of queue
            _pendingOperations.removeAt(0);
            _pendingOperations.add(operation);
            await _savePendingOperations();
            break; // Stop trying for now
          }
        }
      }
    } finally {
      _isSyncing = false;
      _syncController.add(
        SyncStatus(pending: _pendingOperations.length, syncing: false),
      );
    }
  }

  // Check if we're offline
  Future<bool> isOffline() async {
    try {
      await ApiClient.instance.get('/health');
      return false;
    } catch (_) {
      return true;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncController.close();
  }
}

class PendingOperation {
  final String type;
  final String endpoint;
  final Map<String, dynamic> data;
  final int maxRetries;
  int retryCount = 0;

  PendingOperation({
    required this.type,
    required this.endpoint,
    required this.data,
    this.maxRetries = 3,
  });

  Future<void> execute() async {
    switch (type) {
      case 'POST':
        await ApiClient.instance.post(endpoint, body: data);
        break;
      case 'PUT':
        await ApiClient.instance.put(endpoint, body: data);
        break;
      case 'DELETE':
        await ApiClient.instance.delete(endpoint);
        break;
      default:
        throw Exception('Unknown operation type: $type');
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'endpoint': endpoint,
    'data': data,
    'maxRetries': maxRetries,
    'retryCount': retryCount,
  };

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      type: json['type'] as String,
      endpoint: json['endpoint'] as String,
      data: json['data'] as Map<String, dynamic>,
      maxRetries: json['maxRetries'] as int,
    )..retryCount = json['retryCount'] as int;
  }
}

class SyncStatus {
  final int pending;
  final bool syncing;

  const SyncStatus({required this.pending, required this.syncing});
}
