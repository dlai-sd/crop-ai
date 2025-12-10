import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/sync_provider.dart';

class SyncStatusWidget extends ConsumerWidget {
  final double iconSize;
  final bool showLabel;

  const SyncStatusWidget({
    Key? key,
    this.iconSize = 20,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);

    return Tooltip(
      message: _getSyncMessage(syncStatus, lastSync),
      child: _buildSyncIcon(syncStatus),
    );
  }

  Widget _buildSyncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue.shade700,
            ),
          ),
        );

      case SyncStatus.synced:
        return Icon(
          Icons.cloud_done,
          size: iconSize,
          color: Colors.green,
        );

      case SyncStatus.error:
        return Icon(
          Icons.cloud_off,
          size: iconSize,
          color: Colors.red,
        );

      case SyncStatus.offline:
        return Icon(
          Icons.cloud_queue,
          size: iconSize,
          color: Colors.orange,
        );

      case SyncStatus.idle:
        return SizedBox(width: iconSize, height: iconSize);
    }
  }

  String _getSyncMessage(SyncStatus status, DateTime? lastSync) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Syncing data...';
      case SyncStatus.synced:
        return 'Data synced${lastSync != null ? ' at ${lastSync.hour}:${lastSync.minute.toString().padLeft(2, '0')}' : ''}';
      case SyncStatus.error:
        return 'Sync failed - offline mode active';
      case SyncStatus.offline:
        return 'Offline - using cached data';
      case SyncStatus.idle:
        return 'Ready to sync';
    }
  }
}

// Compact sync status for farm cards
class CompactSyncBadge extends ConsumerWidget {
  const CompactSyncBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    if (syncStatus == SyncStatus.idle) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: _getStatusColor(syncStatus),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (syncStatus == SyncStatus.syncing)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(
              _getStatusIcon(syncStatus),
              size: 10,
              color: Colors.white,
            ),
          const SizedBox(width: 4),
          Text(
            _getStatusLabel(syncStatus),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SyncStatus status) => switch (status) {
    SyncStatus.syncing => Colors.blue,
    SyncStatus.synced => Colors.green,
    SyncStatus.error => Colors.red,
    SyncStatus.offline => Colors.orange,
    SyncStatus.idle => Colors.transparent,
  };

  IconData _getStatusIcon(SyncStatus status) => switch (status) {
    SyncStatus.syncing => Icons.sync,
    SyncStatus.synced => Icons.check_circle,
    SyncStatus.error => Icons.error,
    SyncStatus.offline => Icons.cloud_off,
    SyncStatus.idle => Icons.circle,
  };

  String _getStatusLabel(SyncStatus status) => switch (status) {
    SyncStatus.syncing => 'Syncing',
    SyncStatus.synced => 'Synced',
    SyncStatus.error => 'Error',
    SyncStatus.offline => 'Offline',
    SyncStatus.idle => 'Idle',
  };
}
