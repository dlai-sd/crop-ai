import 'package:crop_ai/features/cloud_sync/models/cloud_sync_state.dart';
import 'package:crop_ai/features/cloud_sync/data/database/app_database.dart';
import 'package:crop_ai/features/cloud_sync/data/database/daos.dart';

/// Offline cache service for syncing when connection is restored
/// Integrates with Drift database for local persistence
class OfflineCacheService {
  final AppDatabase database;
  late final SyncEventDao _syncEventDao;
  late final CloudFarmDao _farmDao;
  late final CloudUserDao _userDao;
  late final SyncConflictDao _conflictDao;
  late final SyncMetadataDao _metadataDao;

  OfflineCacheService(this.database) {
    _syncEventDao = SyncEventDao(database);
    _farmDao = CloudFarmDao(database);
    _userDao = CloudUserDao(database);
    _conflictDao = SyncConflictDao(database);
    _metadataDao = SyncMetadataDao(database);
  }

  // ==================== Sync Event Operations ====================

  /// Queue sync event for later upload
  Future<void> queueSyncEvent(SyncEvent event) async {
    try {
      await _syncEventDao.insertSyncEvent(event);
    } catch (e) {
      print('[OfflineCache] Error queuing event: $e');
      rethrow;
    }
  }

  /// Get all pending sync events
  Future<List<SyncEvent>> getPendingSyncEvents() async {
    try {
      return await _syncEventDao.getAllPendingEvents();
    } catch (e) {
      print('[OfflineCache] Error fetching pending events: $e');
      return [];
    }
  }

  /// Get pending sync events for specific farm
  Future<List<SyncEvent>> getPendingEventsForFarm(String farmId) async {
    try {
      return await _syncEventDao.getPendingEventsForFarm(farmId);
    } catch (e) {
      print('[OfflineCache] Error fetching farm events: $e');
      return [];
    }
  }

  /// Mark event as synced
  Future<void> markEventAsSynced(String eventId) async {
    try {
      await _syncEventDao.markEventAsSynced(eventId);
    } catch (e) {
      print('[OfflineCache] Error marking event as synced: $e');
      rethrow;
    }
  }

  /// Mark multiple events as synced
  Future<void> markEventsSynced(List<String> eventIds) async {
    try {
      if (eventIds.isNotEmpty) {
        await _syncEventDao.markEventsSynced(eventIds);
      }
    } catch (e) {
      print('[OfflineCache] Error marking events as synced: $e');
      rethrow;
    }
  }

  /// Clear synced events (cleanup)
  Future<void> clearSyncedEvents({int olderThanDays = 30}) async {
    try {
      await _syncEventDao.clearSyncedEvents(olderThanDays: olderThanDays);
    } catch (e) {
      print('[OfflineCache] Error clearing synced events: $e');
      rethrow;
    }
  }

  /// Get pending events count
  Future<int> getPendingEventsCount() async {
    try {
      return await _syncEventDao.getPendingEventsCount();
    } catch (e) {
      print('[OfflineCache] Error counting pending events: $e');
      return 0;
    }
  }

  // ==================== Farm Caching Operations ====================

  /// Cache farm locally
  Future<void> cacheFarm(CloudFarm farm) async {
    try {
      await _farmDao.insertOrUpdateFarm(farm);
    } catch (e) {
      print('[OfflineCache] Error caching farm: $e');
      rethrow;
    }
  }

  /// Cache multiple farms
  Future<void> cacheFarms(List<CloudFarm> farms) async {
    try {
      for (var farm in farms) {
        await _farmDao.insertOrUpdateFarm(farm);
      }
    } catch (e) {
      print('[OfflineCache] Error caching farms: $e');
      rethrow;
    }
  }

  /// Get cached farm
  Future<CloudFarm?> getCachedFarm(String farmId) async {
    try {
      return await _farmDao.getFarmById(farmId);
    } catch (e) {
      print('[OfflineCache] Error fetching cached farm: $e');
      return null;
    }
  }

  /// Get all cached farms for user
  Future<List<CloudFarm>> getCachedFarmsForUser(String userId) async {
    try {
      return await _farmDao.getFarmsByUserId(userId);
    } catch (e) {
      print('[OfflineCache] Error fetching user farms: $e');
      return [];
    }
  }

  /// Update cached farm
  Future<void> updateCachedFarm(CloudFarm farm) async {
    try {
      await _farmDao.insertOrUpdateFarm(farm);
    } catch (e) {
      print('[OfflineCache] Error updating cached farm: $e');
      rethrow;
    }
  }

  /// Delete cached farm
  Future<void> deleteCachedFarm(String farmId) async {
    try {
      await _farmDao.deleteFarm(farmId);
    } catch (e) {
      print('[OfflineCache] Error deleting cached farm: $e');
      rethrow;
    }
  }

  /// Get farms count
  Future<int> getCachedFarmsCount() async {
    try {
      return await _farmDao.getFarmsCount();
    } catch (e) {
      print('[OfflineCache] Error counting farms: $e');
      return 0;
    }
  }

  // ==================== User Profile Caching ====================

  /// Cache user profile locally
  Future<void> cacheUserProfile(CloudUser user) async {
    try {
      await _userDao.insertOrUpdateUser(user);
    } catch (e) {
      print('[OfflineCache] Error caching user: $e');
      rethrow;
    }
  }

  /// Get cached user profile
  Future<CloudUser?> getCachedUserProfile(String userId) async {
    try {
      return await _userDao.getUserById(userId);
    } catch (e) {
      print('[OfflineCache] Error fetching cached user: $e');
      return null;
    }
  }

  /// Update user last sign-in
  Future<void> updateUserLastSignIn(String userId) async {
    try {
      await _userDao.updateLastSignIn(userId);
    } catch (e) {
      print('[OfflineCache] Error updating last sign-in: $e');
      rethrow;
    }
  }

  // ==================== Conflict Management ====================

  /// Store sync conflict locally
  Future<void> storeConflict(SyncConflict conflict) async {
    try {
      await _conflictDao.insertConflict(conflict);
    } catch (e) {
      print('[OfflineCache] Error storing conflict: $e');
      rethrow;
    }
  }

  /// Get unresolved conflicts
  Future<List<SyncConflict>> getUnresolvedConflicts(String farmId) async {
    try {
      return await _conflictDao.getUnresolvedConflicts(farmId);
    } catch (e) {
      print('[OfflineCache] Error fetching conflicts: $e');
      return [];
    }
  }

  /// Mark conflict as resolved
  Future<void> markConflictResolved(String conflictId, SyncConflict resolved) async {
    try {
      await _conflictDao.markConflictResolved(conflictId, resolved);
    } catch (e) {
      print('[OfflineCache] Error resolving conflict: $e');
      rethrow;
    }
  }

  // ==================== Sync Metadata ====================

  /// Get sync metadata for farm
  Future<SyncMetadata?> getSyncMetadata(String farmId) async {
    try {
      return await _metadataDao.getSyncMetadata(farmId);
    } catch (e) {
      print('[OfflineCache] Error fetching sync metadata: $e');
      return null;
    }
  }

  /// Update sync metadata
  Future<void> updateSyncMetadata(SyncMetadata metadata) async {
    try {
      await _metadataDao.updateSyncMetadata(metadata);
    } catch (e) {
      print('[OfflineCache] Error updating sync metadata: $e');
      rethrow;
    }
  }

  /// Calculate pending sync size (for progress indication)
  Future<int> getPendingSyncSize() async {
    try {
      final events = await _syncEventDao.getAllPendingEvents();
      // Rough estimate: assume ~1KB per event
      return events.length * 1024;
    } catch (e) {
      print('[OfflineCache] Error calculating sync size: $e');
      return 0;
    }
  }


  /// Get sync statistics
  Future<SyncStatistics> getSyncStatistics(String farmId) async {
    try {
      final pending = await getPendingEventsForFarm(farmId);
      final unresolved = await getUnresolvedConflicts(farmId);
      final metadata = await getSyncMetadata(farmId);

      return SyncStatistics(
        farmId: farmId,
        pendingEvents: pending.length,
        unresolvedConflicts: unresolved.length,
        lastSyncTime: metadata?.lastSyncTime,
        totalEventsSynced: metadata?.totalEventsSynced ?? 0,
      );
    } catch (e) {
      print('[OfflineCache] Error getting statistics: $e');
      return SyncStatistics(
        farmId: farmId,
        pendingEvents: 0,
        unresolvedConflicts: 0,
        totalEventsSynced: 0,
      );
    }
  }

  /// Clear all offline data (full reset)
  Future<void> clearAllCache() async {
    try {
      // Clear all events
      await _syncEventDao.clearSyncedEvents(olderThanDays: 0);
      // Clear farms
      final farms = await _farmDao.getFarmsByUserId('');
      for (var farm in farms) {
        await _farmDao.deleteFarm(farm.id);
      }
      print('[OfflineCache] Cleared all cache');
    } catch (e) {
      print('[OfflineCache] Error clearing all cache: $e');
      rethrow;
    }
  }

  /// Get overall offline cache statistics
  Future<OfflineCacheStats> getCacheStatistics() async {
    try {
      final eventCount = await getPendingEventsCount();
      final farmCount = await getCachedFarmsCount();
      final syncSize = await getPendingSyncSize();

      return OfflineCacheStats(
        totalEvents: eventCount,
        totalFarms: farmCount,
        estimatedSizeBytes: syncSize,
        cacheReadyForSync: eventCount > 0,
      );
    } catch (e) {
      print('[OfflineCache] Error getting cache stats: $e');
      return OfflineCacheStats(
        totalEvents: 0,
        totalFarms: 0,
        estimatedSizeBytes: 0,
        cacheReadyForSync: false,
      );
    }
  }

/// Offline cache statistics
class OfflineCacheStats {
  final int totalEvents;
  final int totalFarms;
  final int estimatedSizeBytes;
  final bool cacheReadyForSync;

  OfflineCacheStats({
    required this.totalEvents,
    required this.totalFarms,
    required this.estimatedSizeBytes,
    required this.cacheReadyForSync,
  });

  /// Get human-readable cache size
  String get cacheSizeDisplay {
    if (estimatedSizeBytes < 1024) return '${estimatedSizeBytes}B';
    if (estimatedSizeBytes < 1024 * 1024) return '${(estimatedSizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(estimatedSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Map<String, dynamic> toMap() => {
        'totalEvents': totalEvents,
        'totalFarms': totalFarms,
        'estimatedSizeBytes': estimatedSizeBytes,
        'cacheReadyForSync': cacheReadyForSync,
        'cacheSizeDisplay': cacheSizeDisplay,
      };
}
class SyncMetadata {
  final String farmId;
  final DateTime? lastSyncTime;
  final int totalEventsSynced;
  final int totalConflictsResolved;
  final String lastSyncDirection; // 'upload', 'download', 'bidirectional'

  SyncMetadata({
    required this.farmId,
    this.lastSyncTime,
    this.totalEventsSynced = 0,
    this.totalConflictsResolved = 0,
    this.lastSyncDirection = 'bidirectional',
  });

  SyncMetadata copyWith({
    String? farmId,
    DateTime? lastSyncTime,
    int? totalEventsSynced,
    int? totalConflictsResolved,
    String? lastSyncDirection,
  }) {
    return SyncMetadata(
      farmId: farmId ?? this.farmId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      totalEventsSynced: totalEventsSynced ?? this.totalEventsSynced,
      totalConflictsResolved: totalConflictsResolved ?? this.totalConflictsResolved,
      lastSyncDirection: lastSyncDirection ?? this.lastSyncDirection,
    );
  }

  Map<String, dynamic> toMap() => {
        'farmId': farmId,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
        'totalEventsSynced': totalEventsSynced,
        'totalConflictsResolved': totalConflictsResolved,
        'lastSyncDirection': lastSyncDirection,
      };
}

/// Sync statistics for dashboard display
class SyncStatistics {
  final String farmId;
  final int pendingEvents;
  final int unresolvedConflicts;
  final DateTime? lastSyncTime;
  final int totalEventsSynced;

  SyncStatistics({
    required this.farmId,
    required this.pendingEvents,
    required this.unresolvedConflicts,
    this.lastSyncTime,
    required this.totalEventsSynced,
  });

  /// Last sync time formatted for display
  String get lastSyncDisplay {
    if (lastSyncTime == null) return 'Never synced';

    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${lastSyncTime!.month}/${lastSyncTime!.day}/${lastSyncTime!.year}';
  }

  /// Whether there are items needing attention
  bool get needsAttention => pendingEvents > 0 || unresolvedConflicts > 0;

  Map<String, dynamic> toMap() => {
        'farmId': farmId,
        'pendingEvents': pendingEvents,
        'unresolvedConflicts': unresolvedConflicts,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
        'totalEventsSynced': totalEventsSynced,
        'needsAttention': needsAttention,
      };
}
