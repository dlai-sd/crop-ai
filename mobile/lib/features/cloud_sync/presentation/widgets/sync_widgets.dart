import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/cloud_sync/models/cloud_sync_state.dart';
import 'package:crop_ai/features/cloud_sync/providers/cloud_sync_provider.dart';

class SyncStatusIndicator extends ConsumerWidget {
  final String? farmId;
  final bool compact;

  const SyncStatusIndicator({Key? key, this.farmId, this.compact = false})
      : super(key: key);

  Color _getStatusColor(SyncStatus status, bool isOnline) {
    if (!isOnline) return Colors.orange;

    switch (status) {
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.offline:
        return Colors.orange;
      case SyncStatus.idle:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.cloud_done;
      case SyncStatus.error:
        return Icons.cloud_off;
      case SyncStatus.offline:
        return Icons.cloud_queue;
      case SyncStatus.idle:
        return Icons.cloud;
    }
  }

  String _getStatusText(SyncStatus status, bool isOnline) {
    if (!isOnline) return 'Offline';

    switch (status) {
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.success:
        return 'Synced';
      case SyncStatus.error:
        return 'Error';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.idle:
        return 'Ready';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (farmId == null) {
      return SizedBox.shrink();
    }

    final statsAsync = ref.watch(syncStatisticsProvider(farmId!));

    return statsAsync.when(
      data: (stats) {
        return compact
            ? _buildCompact(stats)
            : _buildFull(context, stats);
      },
      loading: () => _buildLoading(),
      error: (error, stack) => Icon(Icons.error, color: Colors.red),
    );
  }

  Widget _buildCompact(SyncStatistics stats) {
    final hasIssues = stats.needsAttention;
    final color = hasIssues ? Colors.orange : Colors.green;

    return Tooltip(
      message: hasIssues
          ? '${stats.pendingEvents} pending, ${stats.unresolvedConflicts} conflicts'
          : 'All synced',
      child: Icon(
        hasIssues ? Icons.cloud_queue : Icons.cloud_done,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildFull(BuildContext context, SyncStatistics stats) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      stats.needsAttention ? Icons.cloud_queue : Icons.cloud_done,
                      color: stats.needsAttention ? Colors.orange : Colors.green,
                    ),
                    SizedBox(width: 8),
                    Text(
                      stats.needsAttention ? 'Sync needed' : 'Synced',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Text(
                  stats.lastSyncDisplay,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Stats
            if (stats.pendingEvents > 0 || stats.unresolvedConflicts > 0) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration:
                    BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (stats.pendingEvents > 0)
                      Row(
                        children: [
                          Icon(Icons.cloud_upload, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('${stats.pendingEvents} pending'),
                        ],
                      ),
                    if (stats.unresolvedConflicts > 0)
                      Row(
                        children: [
                          Icon(Icons.warning, size: 16, color: Colors.red),
                          SizedBox(width: 4),
                          Text('${stats.unresolvedConflicts} conflicts'),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class SyncProgressDialog extends ConsumerWidget {
  final String farmId;

  const SyncProgressDialog({Key? key, required this.farmId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(syncStatisticsProvider(farmId));
    final isSyncing = ref.watch(isSyncingProvider);

    return AlertDialog(
      title: Text('Sync Status'),
      content: statsAsync.when(
        data: (stats) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              if (isSyncing) ...[
                LinearProgressIndicator(),
                SizedBox(height: 12),
              ],

              // Status items
              _StatusItem(
                icon: Icons.cloud_upload,
                label: 'Pending uploads',
                value: '${stats.pendingEvents}',
                color: Colors.blue,
              ),
              _StatusItem(
                icon: Icons.warning,
                label: 'Conflicts',
                value: '${stats.unresolvedConflicts}',
                color: stats.unresolvedConflicts > 0 ? Colors.red : Colors.green,
              ),
              _StatusItem(
                icon: Icons.done_all,
                label: 'Total synced',
                value: '${stats.totalEventsSynced}',
                color: Colors.green,
              ),
              SizedBox(height: 12),
              Text(
                'Last sync: ${stats.lastSyncDisplay}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
        loading: () => CircularProgressIndicator(),
        error: (error, stack) => Text('Error: $error'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        if (!isSyncing)
          ElevatedButton(
            onPressed: () {
              final syncUseCase = ref.read(syncFarmUseCaseProvider);
              syncUseCase(farmId);
            },
            child: Text('Sync Now'),
          ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class SyncAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? farmId;
  final Widget? title;
  final List<Widget>? actions;

  const SyncAppBar({
    Key? key,
    this.farmId,
    this.title,
    this.actions,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: title,
      actions: [
        if (farmId != null) ...[
          SyncStatusIndicator(farmId: farmId, compact: true),
          SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () {
              final syncUseCase = ref.read(syncFarmUseCaseProvider);
              syncUseCase(farmId!);
            },
          ),
        ],
        ...(actions ?? []),
      ],
    );
  }
}

class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(syncStatisticsProvider('all'));

    return statsAsync.when(
      data: (stats) {
        if (stats.pendingEvents == 0) {
          return SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: Colors.orange,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                '${stats.pendingEvents} changes waiting to sync',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
      loading: () => SizedBox.shrink(),
      error: (_, __) => SizedBox.shrink(),
    );
  }
}
