import 'package:crop_ai/features/cloud_sync/models/cloud_sync_state.dart';

/// Offline cache service for syncing when connection is restored
/// Integrates with Drift database for local storage
class OfflineCacheService {
  // Simulating Drift database access
  // In production, inject actual Drift database instance

  /// Queue sync event for later upload
  Future<void> queueSyncEvent(SyncEvent event) async {
    // In production: await database.syncEventDao.insertSyncEvent(event);
    await Future.delayed(Duration(milliseconds: 50));
  }

  /// Get all pending sync events
  Future<List<SyncEvent>> getPendingSyncEvents() async {
    // In production: return await database.syncEventDao.getAllPendingEvents();
    await Future.delayed(Duration(milliseconds: 100));
    return [];
  }

  /// Get pending sync events for specific farm
  Future<List<SyncEvent>> getPendingEventsForFarm(String farmId) async {
    // In production: query by farmId
    await Future.delayed(Duration(milliseconds: 100));
    return [];
  }

  /// Mark event as synced
  Future<void> markEventAsSynced(String eventId) async {
    // In production: update syncedAt and isUploaded in database
    await Future.delayed(Duration(milliseconds: 50));
  }

  /// Mark multiple events as synced
  Future<void> markEventsSynced(List<String> eventIds) async {
    await Future.delayed(Duration(milliseconds: 50 + eventIds.length * 10));
  }

  /// Clear synced events (cleanup)
  Future<void> clearSyncedEvents({int olderThanDays = 30}) async {
    // In production: delete events where syncedAt < now - 30 days
    await Future.delayed(Duration(milliseconds: 100));
  }

  /// Cache farm locally
  Future<void> cacheFarm(CloudFarm farm) async {
    // In production: await database.farmDao.insertFarm(farm);
    await Future.delayed(Duration(milliseconds: 80));
  }

  /// Cache multiple farms
  Future<void> cacheFarms(List<CloudFarm> farms) async {
    await Future.delayed(Duration(milliseconds: 100 + farms.length * 20));
  }

  /// Get cached farm
  Future<CloudFarm?> getCachedFarm(String farmId) async {
    // In production: return await database.farmDao.getFarmById(farmId);
    await Future.delayed(Duration(milliseconds: 50));
    return null;
  }

  /// Get all cached farms for user
  Future<List<CloudFarm>> getCachedFarmsForUser(String userId) async {
    // In production: return await database.farmDao.getFarmsByUserId(userId);
    await Future.delayed(Duration(milliseconds: 100));
    return [];
  }

  /// Update cached farm
  Future<void> updateCachedFarm(CloudFarm farm) async {
    await Future.delayed(Duration(milliseconds: 80));
  }

  /// Delete cached farm
  Future<void> deleteCachedFarm(String farmId) async {
    await Future.delayed(Duration(milliseconds: 50));
  }

  /// Cache user profile locally
  Future<void> cacheUserProfile(CloudUser user) async {
    // In production: await database.userDao.insertUser(user);
    await Future.delayed(Duration(milliseconds: 50));
  }

  /// Get cached user profile
  Future<CloudUser?> getCachedUserProfile(String userId) async {
    // In production: return await database.userDao.getUserById(userId);
    await Future.delayed(Duration(milliseconds: 50));
    return null;
  }

  /// Store sync conflict locally
  Future<void> storeConflict(SyncConflict conflict) async {
    // In production: await database.conflictDao.insertConflict(conflict);
    await Future.delayed(Duration(milliseconds: 60));
  }

  /// Get unresolved conflicts
  Future<List<SyncConflict>> getUnresolvedConflicts(String farmId) async {
    // In production: return await database.conflictDao.getUnresolved(farmId);
    await Future.delayed(Duration(milliseconds: 100));
    return [];
  }

  /// Mark conflict as resolved
  Future<void> markConflictResolved(String conflictId) async {
    await Future.delayed(Duration(milliseconds: 50));
  }

  /// Get sync metadata for farm
  Future<SyncMetadata?> getSyncMetadata(String farmId) async {
    // In production: return await database.metadataDao.get(farmId);
    await Future.delayed(Duration(milliseconds: 50));
    return null;
  }

  /// Update sync metadata
  Future<void> updateSyncMetadata(SyncMetadata metadata) async {
    await Future.delayed(Duration(milliseconds: 50));
  }

  /// Calculate pending sync size (for progress indication)
  Future<int> getPendingSyncSize() async {
    // In production: get byte size of all pending events
    await Future.delayed(Duration(milliseconds: 100));
    return 0;
  }

  /// Get sync statistics
  Future<SyncStatistics> getSyncStatistics(String farmId) async {
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
  }

  /// Clear all offline data (full reset)
  Future<void> clearAllCache() async {
    await Future.delayed(Duration(milliseconds: 150));
    // In production: delete all records from all tables
  }
}

/// Sync metadata for tracking
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
