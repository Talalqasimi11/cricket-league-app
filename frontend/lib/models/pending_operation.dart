import 'package:hive/hive.dart';

part 'pending_operation.g.dart';

/// Types of operations that can be queued for offline sync
enum OperationType {
  create,
  update,
  delete,
}

/// Represents a pending operation that needs to be synced when online
@HiveType(typeId: 4)
class PendingOperation extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final OperationType operationType;
  @HiveField(2)
  final String entityType; // 'tournament', 'match', 'team', 'player'
  @HiveField(3)
  final int entityId;
  @HiveField(4)
  final Map<String, dynamic> data;
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
  final int retryCount;
  @HiveField(7)
  final DateTime? lastAttempt;
  @HiveField(8)
  final String? errorMessage;
  @HiveField(9)
  final bool requiresConflictResolution;

  PendingOperation({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttempt,
    this.errorMessage,
    this.requiresConflictResolution = false,
  });

  /// Create a new pending operation
  factory PendingOperation.create({
    required OperationType operationType,
    required String entityType,
    required int entityId,
    required Map<String, dynamic> data,
  }) {
    return PendingOperation(
      id: '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      data: data,
      createdAt: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  PendingOperation copyWith({
    String? id,
    OperationType? operationType,
    String? entityType,
    int? entityId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    DateTime? lastAttempt,
    String? errorMessage,
    bool? requiresConflictResolution,
  }) {
    return PendingOperation(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
      requiresConflictResolution: requiresConflictResolution ?? this.requiresConflictResolution,
    );
  }

  /// Mark operation as attempted
  PendingOperation markAttempted({String? error}) {
    return copyWith(
      retryCount: retryCount + 1,
      lastAttempt: DateTime.now(),
      errorMessage: error,
    );
  }

  /// Check if operation should be retried
  bool shouldRetry({int maxRetries = 3}) {
    return retryCount < maxRetries;
  }

  /// Get operation priority (lower number = higher priority)
  int get priority {
    // Create operations have highest priority
    if (operationType == OperationType.create) return 1;
    // Updates have medium priority
    if (operationType == OperationType.update) return 2;
    // Deletes have lowest priority
    return 3;
  }

  /// Get operation description for logging
  String get description {
    return '${operationType.name.toUpperCase()} $entityType (ID: $entityId)';
  }

  @override
  String toString() {
    return 'PendingOperation(id: $id, type: $description, retries: $retryCount, conflict: $requiresConflictResolution)';
  }
}
