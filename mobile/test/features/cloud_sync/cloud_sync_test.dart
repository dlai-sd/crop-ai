import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/cloud_sync/models/cloud_sync_state.dart';
import 'package:crop_ai/features/cloud_sync/data/offline_cache_service.dart';

void main() {
  group('CloudSyncState', () {
    test('copyWith returns new instance with updated fields', () {
      final state1 = CloudSyncState(status: SyncStatus.idle);
      final state2 = state1.copyWith(
        status: SyncStatus.syncing,
        message: 'Syncing...',
      );

      expect(state1.status, equals(SyncStatus.idle));
      expect(state2.status, equals(SyncStatus.syncing));
      expect(state2.message, equals('Syncing...'));
    });

    test('progressPercentage calculates correctly', () {
      final state = CloudSyncState(
        status: SyncStatus.syncing,
        totalChanges: 100,
        pendingChanges: 30,
      );

      expect(state.progressPercentage, equals(70));
    });

    test('isSyncing returns true when status is syncing', () {
      final state = CloudSyncState(status: SyncStatus.syncing);
      expect(state.isSyncing, isTrue);
    });

    test('hasPendingChanges returns true when pendingChanges > 0', () {
      final state = CloudSyncState(
        status: SyncStatus.idle,
        pendingChanges: 5,
      );
      expect(state.hasPendingChanges, isTrue);
    });
  });

  group('SyncEvent', () {
    test('create factory sets correct event type', () {
      final event = SyncEvent.create('farm', 'farm_123', {'name': 'Test'});

      expect(event.eventType, equals(SyncEventType.create));
      expect(event.entityType, equals('farm'));
      expect(event.entityId, equals('farm_123'));
      expect(event.isUploaded, isFalse);
    });

    test('update factory sets correct event type', () {
      final event = SyncEvent.update('prediction', 'pred_456', {'value': 0.8});

      expect(event.eventType, equals(SyncEventType.update));
      expect(event.entityType, equals('prediction'));
    });

    test('delete factory creates delete event', () {
      final event = SyncEvent.delete('farm', 'farm_789');

      expect(event.eventType, equals(SyncEventType.delete));
      expect(event.data.containsKey('deletedAt'), isTrue);
    });

    test('markAsSynced updates timestamp and uploaded flag', () {
      final event = SyncEvent.create('farm', 'farm_123', {});
      final synced = event.markAsSynced();

      expect(synced.isUploaded, isTrue);
      expect(synced.syncedAt, isNotNull);
    });

    test('toMap and fromMap roundtrip', () {
      final original = SyncEvent.create('farm', 'farm_123', {'name': 'Test Farm'});
      final map = original.toMap();
      final restored = SyncEvent.fromMap(map);

      expect(restored.entityType, equals(original.entityType));
      expect(restored.entityId, equals(original.entityId));
      expect(restored.data, equals(original.data));
    });
  });

  group('SyncConflict', () {
    test('detect factory creates conflict with both versions', () {
      final conflict = SyncConflict.detect(
        'farm',
        'farm_123',
        {'version': 1},
        {'version': 2},
      );

      expect(conflict.localVersion, equals({'version': 1}));
      expect(conflict.remoteVersion, equals({'version': 2}));
      expect(conflict.isResolved, isFalse);
    });

    test('resolveWithLocal sets resolution flag', () {
      final conflict = SyncConflict.detect('farm', 'farm_123', {'v': 1}, {'v': 2});
      final resolved = conflict.resolveWithLocal();

      expect(resolved.isResolved, isTrue);
      expect(resolved.resolution, equals('local_wins'));
      expect(resolved.mergedVersion, equals({'v': 1}));
    });

    test('resolveWithRemote sets resolution flag', () {
      final conflict = SyncConflict.detect('farm', 'farm_123', {'v': 1}, {'v': 2});
      final resolved = conflict.resolveWithRemote();

      expect(resolved.isResolved, isTrue);
      expect(resolved.resolution, equals('remote_wins'));
      expect(resolved.mergedVersion, equals({'v': 2}));
    });
  });

  group('CloudUser', () {
    test('fromFirebaseUser creates user with defaults', () {
      final user = CloudUser.fromFirebaseUser(
        uid: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      expect(user.uid, equals('user_123'));
      expect(user.email, equals('test@example.com'));
      expect(user.displayName, equals('Test User'));
      expect(user.emailVerified, isFalse);
      expect(user.farmsOwned, isEmpty);
    });

    test('copyWith updates specific fields', () {
      final user1 = CloudUser(
        uid: 'user_123',
        email: 'test@example.com',
        displayName: 'Old Name',
        createdAt: DateTime.now(),
        lastSignIn: DateTime.now(),
      );

      final user2 = user1.copyWith(displayName: 'New Name');

      expect(user1.displayName, equals('Old Name'));
      expect(user2.displayName, equals('New Name'));
      expect(user2.email, equals(user1.email));
    });

    test('toMap and fromMap roundtrip', () {
      final now = DateTime.now();
      final original = CloudUser(
        uid: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: now,
        lastSignIn: now,
        farmsOwned: ['farm_1', 'farm_2'],
      );

      final map = original.toMap();
      final restored = CloudUser.fromMap(map);

      expect(restored.uid, equals(original.uid));
      expect(restored.email, equals(original.email));
      expect(restored.farmsOwned, equals(original.farmsOwned));
    });
  });

  group('CloudFarm', () {
    test('create factory generates new farm with ID', () {
      final farm = CloudFarm.create(
        userId: 'user_123',
        name: 'Test Farm',
        location: 'Pune',
        areaHectares: 10.5,
        cropType: 'wheat',
      );

      expect(farm.userId, equals('user_123'));
      expect(farm.name, equals('Test Farm'));
      expect(farm.version, equals(1));
      expect(farm.isShared, isFalse);
    });

    test('copyWith increments version', () {
      final farm1 = CloudFarm.create(
        userId: 'user_123',
        name: 'Farm',
        location: 'Pune',
        areaHectares: 10,
        cropType: 'rice',
      );

      final farm2 = farm1.copyWith(name: 'Updated Farm', version: farm1.version + 1);

      expect(farm1.version, equals(1));
      expect(farm2.version, equals(2));
      expect(farm2.name, equals('Updated Farm'));
    });

    test('toMap and fromMap preserve all fields', () {
      final original = CloudFarm.create(
        userId: 'user_123',
        name: 'Test Farm',
        location: 'Pune',
        areaHectares: 15.5,
        cropType: 'cotton',
      );

      final map = original.toMap();
      final restored = CloudFarm.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.areaHectares, equals(original.areaHectares));
      expect(restored.cropType, equals(original.cropType));
    });
  });

  group('SyncMetadata', () {
    test('copyWith updates fields', () {
      final meta1 = SyncMetadata(farmId: 'farm_123');
      final meta2 = meta1.copyWith(
        totalEventsSynced: 10,
        lastSyncDirection: 'upload',
      );

      expect(meta1.totalEventsSynced, equals(0));
      expect(meta2.totalEventsSynced, equals(10));
      expect(meta2.lastSyncDirection, equals('upload'));
    });

    test('toMap serializes all fields', () {
      final now = DateTime.now();
      final meta = SyncMetadata(
        farmId: 'farm_123',
        lastSyncTime: now,
        totalEventsSynced: 50,
      );

      final map = meta.toMap();

      expect(map['farmId'], equals('farm_123'));
      expect(map['totalEventsSynced'], equals(50));
    });
  });

  group('SyncStatistics', () {
    test('lastSyncDisplay formats time correctly', () {
      final stats = SyncStatistics(
        farmId: 'farm_123',
        pendingEvents: 0,
        unresolvedConflicts: 0,
        lastSyncTime: null,
        totalEventsSynced: 0,
      );

      expect(stats.lastSyncDisplay, equals('Never synced'));
    });

    test('needsAttention returns true when pending or conflicts', () {
      final stats1 = SyncStatistics(
        farmId: 'farm_123',
        pendingEvents: 5,
        unresolvedConflicts: 0,
        totalEventsSynced: 0,
      );

      expect(stats1.needsAttention, isTrue);

      final stats2 = SyncStatistics(
        farmId: 'farm_123',
        pendingEvents: 0,
        unresolvedConflicts: 0,
        totalEventsSynced: 10,
      );

      expect(stats2.needsAttention, isFalse);
    });
  });
}
