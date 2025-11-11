import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/offline/offline_manager.dart';
import '../core/theme/theme_config.dart';
import '../models/pending_operation.dart';

/// Widget that shows online/offline status and pending operations count
class OfflineStatusIndicator extends StatelessWidget {
  final bool showPendingCount;

  const OfflineStatusIndicator({super.key, this.showPendingCount = true});

  @override
  Widget build(BuildContext context) {
    final offlineManager = Provider.of<OfflineManager>(context, listen: false);

    return StreamBuilder<bool>(
      stream: offlineManager.onlineStatus,
      initialData: offlineManager.isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        if (isOnline && !showPendingCount) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<int>(
          stream: offlineManager.pendingOperationsCount,
          initialData: offlineManager.getPendingOperationsCount(),
          builder: (context, pendingSnapshot) {
            final pendingCount = pendingSnapshot.data ?? 0;

            if (isOnline && pendingCount == 0) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isOnline
                    ? AppColors.secondaryGreen.withValues(alpha: 0.1)
                    : AppColors.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnline ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: isOnline
                        ? AppColors.secondaryGreen
                        : AppColors.errorRed,
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$pendingCount pending',
                      style: AppTypographyExtended.labelSmall.copyWith(
                        color: isOnline
                            ? AppColors.secondaryGreen
                            : AppColors.errorRed,
                      ),
                    ),
                  ] else if (!isOnline) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Offline',
                      style: AppTypographyExtended.labelSmall.copyWith(
                        color: AppColors.errorRed,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Badge widget to show pending operations count
class PendingOperationsBadge extends StatelessWidget {
  const PendingOperationsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineManager = Provider.of<OfflineManager>(context, listen: false);

    return StreamBuilder<int>(
      stream: offlineManager.pendingOperationsCount,
      initialData: offlineManager.getPendingOperationsCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.errorRed,
            shape: BoxShape.circle,
          ),
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          child: Center(
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full screen widget to show pending operations
class PendingOperationsScreen extends StatelessWidget {
  const PendingOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineManager = Provider.of<OfflineManager>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Operations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final result = await offlineManager.syncNow();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success
                          ? 'Sync completed: ${result.operationsProcessed} processed'
                          : 'Sync failed: ${result.errors.join(", ")}',
                    ),
                    backgroundColor: result.success
                        ? AppColors.secondaryGreen
                        : AppColors.errorRed,
                  ),
                );
              }
            },
            tooltip: 'Sync now',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Operations'),
                  content: const Text(
                    'Are you sure you want to clear all pending operations? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await offlineManager.clearPendingOperations();
              }
            },
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: StreamBuilder<int>(
        stream: offlineManager.pendingOperationsCount,
        initialData: offlineManager.getPendingOperationsCount(),
        builder: (context, snapshot) {
          final operations = offlineManager.getPendingOperations();

          if (operations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: AppColors.secondaryGreen,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'No pending operations',
                    style: AppTypographyExtended.headlineMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: operations.length,
            itemBuilder: (context, index) {
              final op = operations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getOperationColor(op.operationType),
                    child: Icon(
                      _getOperationIcon(op.operationType),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(op.description),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Created: ${_formatDate(op.createdAt)}'),
                      if (op.retryCount > 0) Text('Attempts: ${op.retryCount}'),
                    ],
                  ),
                  trailing: Text(
                    'Priority: ${op.priority}',
                    style: AppTypographyExtended.labelSmall,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getOperationColor(OperationType type) {
    switch (type) {
      case OperationType.create:
        return AppColors.secondaryGreen;
      case OperationType.update:
        return AppColors.primaryBlue;
      case OperationType.delete:
        return AppColors.errorRed;
    }
  }

  IconData _getOperationIcon(OperationType type) {
    switch (type) {
      case OperationType.create:
        return Icons.add;
      case OperationType.update:
        return Icons.edit;
      case OperationType.delete:
        return Icons.delete;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
