import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/cloud_sync/models/cloud_sync_state.dart';
import 'package:crop_ai/features/cloud_sync/data/offline_cache_service.dart';

void main() {
  group('SyncMetadata Model Tests', () {
    test('copyWith updates specific fields', () {
      final original = SyncMetadata(
        farmId: 'farm123',
        lastSyncTime: DateTime(2025, 12, 9),
        totalEventsSynced: 10,
        totalConflictsResolved: 2,
        lastSyncDirection: 'upload',
      );

      final updated = original.copyWith(
        totalEventsSynced: 15,
        lastSyncDirection: 'bidirectional',
      );

      expect(updated.farmId, equals('farm123'));
      expect(updated.lastSyncTime, equals(original.lastSyncTime));
      expect(updated.totalEventsSynced, equals(15));
      expect(updated.totalConflictsResolved, equals(2));
      expect(updated.lastSyncDirection, equals('bidirectional'));
    });

    test('toMap serialization includes all fields', () {
      final now = DateTime.now();
      final metadata = SyncMetadata(
        farmId: 'farm123',
        lastSyncTime: now,
        totalEventsSynced: 10,
        totalConflictsResolved: 2,
        lastSyncDirection: 'bidirectional',
      );

      final map = metadata.toMap();

      expect(map['farmId'], equals('farm123'));
      expect(map['totalEventsSynced'], equals(10));
      expect(map['totalConflictsResolved'], equals(2));
      expect(map['lastSyncDirection'], equals('bidirectional'));
      expect(map['lastSyncTime'], isNotEmpty);
    });
  });

  group('SyncStatistics Model Tests', () {
    test('needsAttention is true when events pending', () {
      final stats = SyncStatistics(
        farmId: 'farm123',
        pendingEvents: 5,
        unresolvedConflicts: 0,
        totalEventsSynced: 100,
      );

      expect(stats.needsAttention, isTrue);
    });

    test('needsAttention is true when conflicts unresolved', () {
      final stats = SyncStatistics(
        farmId: 'farm123',
        pendingEvents: 0,
        unresolvedConflicts: 3,
        totalEventsSynced: 100,
      );

      expect(stats.needsAttention, isTrue);
    });

    test('needsAttention is false when all clear', () {
      final stats = SyncStatistics(
        farmId: 'farm123',
        pendingEvents: 0,
        unresolvedConflicts: 0,
        totalEventsSynced: 100,
      );

      expect(stats.needsAttention, isFalse);
    });

    test('lastSyncDisplay shows "Just now" for recent sync', () {
      final now = DateTime.now();
      final stats = SyncStatistics(
        farmId: 'farm123',
        pendingEvents: 0,
        unresolvedConflicts: 0,
        totalEventsSynced: 100,
        lastSyncTime: now,
      );

      expect(stats.lastSyncDisplay, equals('Just now'));
    });

    test('lastSyncDisplay shows minutes ago', () {
      final fiveMinutesAgo = DateTime.now().subtract(Duration(minutes: 5));
      final stats = SyncStatistics(
        farmId: 'farm123',
        pendingEvents: 0,
        unresolvedConflicts: 0,
        totalEventsSynced: 100,
        lastSyncTime: fiveMinutesAgo,
      );

      expect(stats.lastSyncDisplay, contains('5m'));
    });

    test('lastSyncDisplay shows hours ago', () {
      final twoHoursAgo = DateTime.now().subtract(Duration(hours: 2));
      final stats = SyncStatistics(
        farmId: 'farm123',
        pendingEvents: 0,
        unresolvedConflicts: 0,
        totalEventsSynced: 100,
        lastSyncTime: twoHoursAgo,
      );

      expect(stats.lastSyncDisplay, contains('2h'));
    });

    test('lastSyncDisplay shows days ago', () {
      final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
      final stats = SyncStatistics(
        farmId: 'farm123',
        pendingEvents: 0,
        unresolvedConflicts: 0,
        totalEventsSynced: 100,
        lastSyncTime: threeDaysAgo,
      );

      expect(stats.lastSyncDisplay, contains('3d'));
    });

    test('lastSyncDisplay shows "Never synced" when null', () {
      final stats = SyncStatistics(
        farmId: 'farm123',
        pendingEvents: 0,
        unresolvedConflicts: 0,
        totalEventsSynced: 0,
      );

      expect(stats.lastSyncDisplay, equals('Never synced'));
    });

    test('toMap serialization includes all fields', () {
      final stats = SyncStatistics(
        farmId: 'farm123',
        pendingEvents: 5,
        unresolvedConflicts: 2,
        totalEventsSynced: 100,
      );

      final map = stats.toMap();

      expect(map['farmId'], equals('farm123'));
      expect(map['pendingEvents'], equals(5));
      expect(map['unresolvedConflicts'], equals(2));
      expect(map['totalEventsSynced'], equals(100));
      expect(map['needsAttention'], isTrue);
    });
  });

  group('OfflineCacheStats Model Tests', () {
    test('cacheSizeDisplay formats bytes correctly', () {
      final stats1 = OfflineCacheStats(
        totalEvents: 5,
        totalFarms: 2,
        estimatedSizeBytes: 512, // 512B
        cacheReadyForSync: true,
      );
      expect(stats1.cacheSizeDisplay, contains('B'));

      final stats2 = OfflineCacheStats(
        totalEvents: 5,
        totalFarms: 2,
        estimatedSizeBytes: 51200, // 50KB
        cacheReadyForSync: true,
      );
      expect(stats2.cacheSizeDisplay, contains('KB'));

      final stats3 = OfflineCacheStats(
        totalEvents: 5,
        totalFarms: 2,
        estimatedSizeBytes: 5242880, // 5MB
        cacheReadyForSync: true,
      );
      expect(stats3.cacheSizeDisplay, contains('MB'));
    });

    test('toMap serialization includes display size', () {
      final stats = OfflineCacheStats(
        totalEvents: 10,
        totalFarms: 3,
        estimatedSizeBytes: 102400, // 100KB
        cacheReadyForSync: true,
      );

      final map = stats.toMap();

      expect(map['totalEvents'], equals(10));
      expect(map['totalFarms'], equals(3));
      expect(map['estimatedSizeBytes'], equals(102400));
      expect(map['cacheReadyForSync'], isTrue);
      expect(map['cacheSizeDisplay'], isNotEmpty);
    });

    test('cacheReadyForSync indicates sync status', () {
      final ready = OfflineCacheStats(
        totalEvents: 5,
        totalFarms: 2,
        estimatedSizeBytes: 51200,
        cacheReadyForSync: true,
      );
      expect(ready.cacheReadyForSync, isTrue);

      final notReady = OfflineCacheStats(
        totalEvents: 0,
        totalFarms: 0,
        estimatedSizeBytes: 0,
        cacheReadyForSync: false,
      );
      expect(notReady.cacheReadyForSync, isFalse);
    });
  });

  group('Sync Models Integration', () {
    test('SyncMetadata with SyncStatistics workflow', () {
      // Create metadata
      final now = DateTime.now();
      final metadata = SyncMetadata(
        farmId: 'farm123',
        lastSyncTime: now,
        totalEventsSynced: 100,
        totalConflictsResolved: 5,
      );

      // Create statistics
      final stats = SyncStatistics(
        farmId: 'farm123',
        pendingEvents: 3,
        unresolvedConflicts: 1,
        lastSyncTime: metadata.lastSyncTime,
        totalEventsSynced: metadata.totalEventsSynced,
      );

      // Verify integration
      expect(stats.farmId, equals(metadata.farmId));
      expect(stats.totalEventsSynced, equals(metadata.totalEventsSynced));
      expect(stats.lastSyncTime, equals(metadata.lastSyncTime));
    });

    test('OfflineCacheStats tracks readiness changes', () {
      // Initially has pending events
      final initialStats = OfflineCacheStats(
        totalEvents: 10,
        totalFarms: 3,
        estimatedSizeBytes: 102400,
        cacheReadyForSync: true,
      );
      expect(initialStats.cacheReadyForSync, isTrue);

      // After sync completes
      final afterSyncStats = OfflineCacheStats(
        totalEvents: 0,
        totalFarms: 3,
        estimatedSizeBytes: 0,
        cacheReadyForSync: false,
      );
      expect(afterSyncStats.cacheReadyForSync, isFalse);
    });
  });
}
