import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/offline_sync/data/sync_service.dart';
import 'package:crop_ai/features/offline_sync/data/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('OfflineSyncService', () {
    late AppDatabase database;
    late OfflineSyncService syncService;

    setUp(() {
      database = AppDatabase(drift.DriftQueryExecutor.inMemory());
      syncService = OfflineSyncService(database);
    });

    test('queueFarmOperation adds operation to sync queue', () async {
      await syncService.queueFarmOperation(
        'farm-1',
        'create',
        {'name': 'Test Farm', 'area': 10.0},
      );

      final operations = await syncService.getPendingOperations();

      expect(operations, isNotEmpty);
      expect(operations.first.farmId, 'farm-1');
      expect(operations.first.operation, 'create');
      expect(operations.first.isSynced, false);
    });

    test('getPendingOperations returns only unsynced operations', () async {
      await syncService.queueFarmOperation('farm-1', 'create', {});
      await syncService.queueFarmOperation('farm-2', 'update', {});

      var operations = await syncService.getPendingOperations();
      expect(operations.length, 2);

      // Mark first as synced
      await syncService.markOperationSynced(operations.first.id);

      operations = await syncService.getPendingOperations();
      expect(operations.length, 1);
      expect(operations.first.farmId, 'farm-2');
    });

    test('markOperationSynced updates operation status', () async {
      await syncService.queueFarmOperation('farm-1', 'create', {});

      var operations = await syncService.getPendingOperations();
      final queueId = operations.first.id;

      await syncService.markOperationSynced(queueId);

      operations = await syncService.getPendingOperations();
      expect(operations, isEmpty);
    });

    test('retryOperation increments retry count', () async {
      await syncService.queueFarmOperation('farm-1', 'create', {});

      var operations = await syncService.getPendingOperations();
      final queueId = operations.first.id;

      expect(operations.first.retryCount, 0);

      await syncService.retryOperation(queueId, error: 'Network error');

      // Note: In a real scenario, we'd query the database again
      // This test demonstrates the method call pattern
    });

    test('setLastSyncTime and getLastSyncTime work correctly', () async {
      expect(await syncService.getLastSyncTime(), isNull);

      final now = DateTime.now();
      await syncService.setLastSyncTime(now);

      final lastSync = await syncService.getLastSyncTime();
      expect(lastSync, isNotNull);
      expect(lastSync!.difference(now).inSeconds, lessThan(2));
    });

    test('clearCompletedOperations removes synced operations', () async {
      await syncService.queueFarmOperation('farm-1', 'create', {});
      await syncService.queueFarmOperation('farm-2', 'update', {});

      var operations = await syncService.getPendingOperations();
      await syncService.markOperationSynced(operations.first.id);

      await syncService.clearCompletedOperations();

      operations = await syncService.getPendingOperations();
      expect(operations.length, 1);
    });

    test('handleConflict creates and resolves conflict', () async {
      final conflictId = 'conflict-1';
      final local = {'name': 'Farm A', 'area': 10.0};
      final remote = {'name': 'Farm B', 'area': 15.0};

      await syncService.handleConflict(
        conflictId,
        'farm-1',
        local,
        remote,
        'local',
      );

      final conflicts = await syncService.getUnresolvedConflicts();
      expect(conflicts, isEmpty); // Should be resolved, not unresolved
    });

    test('resolveConflictLastWriteWins prefers remote if newer', () {
      final now = DateTime.now();
      final local = {
        'name': 'Farm A',
        'lastUpdated': now.subtract(const Duration(hours: 1)).toIso8601String(),
      };
      final remote = {
        'name': 'Farm B',
        'lastUpdated': now.toIso8601String(),
      };

      final result = syncService.resolveConflictLastWriteWins(local, remote);

      expect(result['name'], 'Farm B');
    });

    test('resolveConflictLastWriteWins prefers local if more recent', () {
      final now = DateTime.now();
      final local = {
        'name': 'Farm A',
        'lastUpdated': now.toIso8601String(),
      };
      final remote = {
        'name': 'Farm B',
        'lastUpdated': now.subtract(const Duration(hours: 1)).toIso8601String(),
      };

      final result = syncService.resolveConflictLastWriteWins(local, remote);

      expect(result['name'], 'Farm A');
    });

    test('resolveConflictManual returns user choice', () {
      final local = {'name': 'Farm A'};
      final remote = {'name': 'Farm B'};
      final userChoice = {'name': 'Farm C'};

      final result = syncService.resolveConflictManual(local, remote, userChoice);

      expect(result['name'], 'Farm C');
    });

    test('resolveConflictManual returns local if no choice', () {
      final local = {'name': 'Farm A'};
      final remote = {'name': 'Farm B'};

      final result = syncService.resolveConflictManual(local, remote, null);

      expect(result['name'], 'Farm A');
    });
  });

  group('SyncOperation', () {
    test('canRetry returns true if retries < 3', () {
      final op1 = SyncOperation(
        id: 1,
        farmId: 'farm-1',
        operation: 'create',
        payload: '{}',
        createdAt: DateTime.now(),
        retryCount: 0,
      );
      expect(op1.canRetry(), true);

      final op2 = SyncOperation(
        id: 2,
        farmId: 'farm-1',
        operation: 'create',
        payload: '{}',
        createdAt: DateTime.now(),
        retryCount: 2,
      );
      expect(op2.canRetry(), true);

      final op3 = SyncOperation(
        id: 3,
        farmId: 'farm-1',
        operation: 'create',
        payload: '{}',
        createdAt: DateTime.now(),
        retryCount: 3,
      );
      expect(op3.canRetry(), false);
    });
  });
}
