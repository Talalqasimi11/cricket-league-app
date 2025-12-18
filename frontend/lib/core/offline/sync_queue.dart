import 'package:flutter/foundation.dart';
import 'package:frontend/core/offline/conflict_resolver.dart';

/// Simple notification-only SyncQueue that integrates with conflict resolution.
/// This avoids circular imports by implementing the listener interface.
class SyncQueue implements ConflictResolutionListener {
  static SyncQueue? _instance;
  static SyncQueue get instance => _instance ??= SyncQueue._();

  SyncQueue._() {
    // Register as the listener so ConflictResolver can notify us
    ConflictResolver.setResolutionListener(this);
  }

  /// Called by ConflictResolver when a conflict has been resolved
  @override
  Future<void> onConflictResolved(
    String operationId,
    ConflictResolution resolution,
  ) async {
    try {
      debugPrint('[SyncQueue] Conflict resolved for operation: $operationId');
      debugPrint('[SyncQueue] Strategy: ${resolution.appliedStrategy.name}');
      debugPrint(
          '[SyncQueue] Resolved data is ready for any post-processing in the queue');
    } catch (e) {
      debugPrint('[SyncQueue] Error processing conflict resolution: $e');
    }
  }

  /// Check if the SyncQueue is initialized (always true for this simple implementation)
  bool get isInitialized => true;

  /// Get sync statistics (placeholder implementation)
  Map<String, dynamic> getSyncStats() {
    return {
      'totalPending': 0,
      'isOnline': true,
      'initialized': true,
      'status': 'SyncQueue ready for conflict resolution notifications',
    };
  }
}