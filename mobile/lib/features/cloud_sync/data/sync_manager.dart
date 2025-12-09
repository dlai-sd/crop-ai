import 'package:crop_ai/features/cloud_sync/models/cloud_sync_state.dart';
import 'package:crop_ai/features/cloud_sync/data/firebase_repository.dart';
import 'package:crop_ai/features/cloud_sync/data/offline_cache_service.dart';

/// Sync manager orchestrates cloud sync operations
/// Handles: upload, download, conflict resolution, offline queuing
class SyncManager {
  final FirebaseRepository firebaseRepository;
  final OfflineCacheService offlineCache;

  // Current sync state
  CloudSyncState _syncState = CloudSyncState(status: SyncStatus.idle);

  // Listeners for sync state changes
  final List<Function(CloudSyncState)> _listeners = [];

  SyncManager({
    required this.firebaseRepository,
    required this.offlineCache,
  });

  /// Get current sync state
  CloudSyncState get syncState => _syncState;

  /// Listen to sync state changes
  void addListener(Function(CloudSyncState) listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(Function(CloudSyncState) listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of state change
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_syncState);
    }
  }

  /// Update sync state
  void _updateSyncState(CloudSyncState newState) {
    _syncState = newState;
    _notifyListeners();
  }

  /// Start bidirectional sync for farm
  Future<void> syncFarm(String farmId) async {
    // Check connection first
    final isConnected = await firebaseRepository.isConnected();

    _updateSyncState(
      _syncState.copyWith(
        status: SyncStatus.syncing,
        isOnline: isConnected,
        message: isConnected ? 'Starting sync...' : 'Offline - queuing changes',
      ),
    );

    if (!isConnected) {
      _updateSyncState(
        _syncState.copyWith(
          status: SyncStatus.offline,
          message: 'No internet connection. Changes will sync when online.',
        ),
      );
      return;
    }

    try {
      // Step 1: Upload local changes
      await _uploadLocalChanges(farmId);

      // Step 2: Download remote changes
      await _downloadRemoteChanges(farmId);

      // Step 3: Check for conflicts
      await _handleConflicts(farmId);

      // Step 4: Update sync time
      await firebaseRepository.saveLastSyncTime(farmId);

      _updateSyncState(
        _syncState.copyWith(
          status: SyncStatus.success,
          message: 'Sync complete',
          lastSyncTime: DateTime.now(),
          pendingChanges: 0,
        ),
      );
    } catch (e) {
      _updateSyncState(
        _syncState.copyWith(
          status: SyncStatus.error,
          message: 'Sync failed: $e',
          errorCode: 'SYNC_ERROR',
        ),
      );
      rethrow;
    }
  }

  /// Upload pending local changes to cloud
  Future<void> _uploadLocalChanges(String farmId) async {
    final pendingEvents = await offlineCache.getPendingEventsForFarm(farmId);

    if (pendingEvents.isEmpty) return;

    _updateSyncState(
      _syncState.copyWith(
        message: 'Uploading changes...',
        totalChanges: pendingEvents.length,
        pendingChanges: pendingEvents.length,
      ),
    );

    // Upload in batches
    const batchSize = 10;
    for (int i = 0; i < pendingEvents.length; i += batchSize) {
      final batch = pendingEvents.sublist(
        i,
        i + batchSize > pendingEvents.length ? pendingEvents.length : i + batchSize,
      );

      await firebaseRepository.uploadSyncEventsBatch(batch);

      // Mark as uploaded
      for (var event in batch) {
        await offlineCache.markEventAsSynced(event.id);
      }

      // Update progress
      final synced = (i + batch.length);
      _updateSyncState(
        _syncState.copyWith(
          pendingChanges: pendingEvents.length - synced,
          totalChanges: pendingEvents.length,
        ),
      );
    }
  }

  /// Download remote changes from cloud
  Future<void> _downloadRemoteChanges(String farmId) async {
    _updateSyncState(_syncState.copyWith(message: 'Downloading changes...'));

    final lastSync = await firebaseRepository.getLastSyncTime(farmId);
    final remoteEvents = await firebaseRepository.downloadSyncEvents(
      farmId: farmId,
      since: lastSync ?? DateTime.now().subtract(Duration(days: 365)),
    );

    if (remoteEvents.isEmpty) return;

    _updateSyncState(
      _syncState.copyWith(
        message: 'Applying remote changes...',
        totalChanges: ((_syncState.totalChanges) + remoteEvents.length),
      ),
    );

    // Apply each event to local cache
    for (var event in remoteEvents) {
      await _applyRemoteEvent(event);
    }
  }

  /// Apply a remote event to local database
  Future<void> _applyRemoteEvent(SyncEvent event) async {
    // In production: apply to local database based on event type
    // For now, just cache it
    await offlineCache.queueSyncEvent(event);
  }

  /// Handle sync conflicts with conflict resolution
  Future<void> _handleConflicts(String farmId) async {
    final conflicts = await firebaseRepository.getSyncConflicts(farmId);

    if (conflicts.isEmpty) return;

    _updateSyncState(
      _syncState.copyWith(
        message: 'Resolving conflicts...',
      ),
    );

    for (var conflict in conflicts) {
      // Default: prefer remote version (server as source of truth)
      final resolved = conflict.resolveWithRemote();
      await firebaseRepository.resolveConflict(resolved);
      await offlineCache.markConflictResolved(conflict.id);
    }
  }

  /// Queue local change for sync
  Future<void> queueLocalChange({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    required SyncEventType eventType,
  }) async {
    final event = SyncEvent(
      id: '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      eventType: eventType,
      data: data,
      createdAt: DateTime.now(),
    );

    await offlineCache.queueSyncEvent(event);

    // Update total pending
    _updateSyncState(
      _syncState.copyWith(
        pendingChanges: _syncState.pendingChanges + 1,
      ),
    );
  }

  /// Get sync statistics
  Future<SyncStatistics> getSyncStatistics(String farmId) async {
    return offlineCache.getSyncStatistics(farmId);
  }

  /// Force sync all farms for user
  Future<void> syncAllFarms(List<String> farmIds) async {
    for (var farmId in farmIds) {
      await syncFarm(farmId);
    }
  }

  /// Stop current sync operation
  void stop() {
    _updateSyncState(
      _syncState.copyWith(
        status: SyncStatus.idle,
        message: 'Sync stopped',
      ),
    );
  }

  /// Clear all offline data (logout cleanup)
  Future<void> clearAllData() async {
    await offlineCache.clearAllCache();
    _updateSyncState(CloudSyncState(status: SyncStatus.idle));
  }

  /// Monitor connection status
  Future<void> startMonitoringConnection() async {
    // In production: use connectivity package or Firebase connectivity monitoring
    // For now, periodic checks
    while (true) {
      await Future.delayed(Duration(seconds: 5));
      final isConnected = await firebaseRepository.isConnected();

      if (isConnected != _syncState.isOnline) {
        _updateSyncState(
          _syncState.copyWith(
            isOnline: isConnected,
            message: isConnected
                ? 'Back online - ready to sync'
                : 'Connection lost - changes will queue',
          ),
        );

        // Auto-sync when connection restored
        if (isConnected && _syncState.hasPendingChanges) {
          // Trigger sync in background (don't await)
          // In production: implement background sync
        }
      }
    }
  }
}
