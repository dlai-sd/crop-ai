import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:crop_ai/features/offline_sync/data/database/app_database.dart';

// Database provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  // Initialize database
  final database = AppDatabase(drift.DriftQueryExecutor.inMemory());
  return database;
});

// Sync service provider
final syncServiceProvider = Provider<OfflineSyncService>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return OfflineSyncService(database);
});

/// Offline sync service for managing local-remote sync
class OfflineSyncService {
  final AppDatabase _database;

  OfflineSyncService(this._database);

  /// Queue a farm operation
  Future<void> queueFarmOperation(String farmId, String operation, Map<String, dynamic> payload) async {
    await _database.queueOperation(farmId, operation, payload);
  }

  /// Get all pending operations
  Future<List<SyncOperation>> getPendingOperations() async {
    final rows = await _database.getPendingSyncOperations();
    return rows
        .map((row) => SyncOperation(
              id: row.id,
              farmId: row.farmId,
              operation: row.operation,
              payload: row.payload,
              createdAt: row.createdAt,
              retryCount: row.retryCount,
            ))
        .toList();
  }

  /// Mark operation as synced
  Future<void> markOperationSynced(int queueId) async {
    await _database.markOperationSynced(queueId);
  }

  /// Retry failed operation
  Future<void> retryOperation(int queueId, {String? error}) async {
    await _database.updateSyncRetry(queueId, error);
  }

  /// Handle sync conflict
  Future<void> handleConflict(
    String conflictId,
    String farmId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    String resolution,
  ) async {
    await _database.createConflict(conflictId, farmId, localData, remoteData);
    await _database.resolveConflict(conflictId, resolution);
  }

  /// Get unresolved conflicts
  Future<List<SyncConflictData>> getUnresolvedConflicts() async {
    final rows = await _database.getUnresolvedConflicts();
    return rows
        .map((row) => SyncConflictData(
              id: row.id,
              farmId: row.farmId,
              localData: row.localData,
              remoteData: row.remoteData,
              createdAt: row.createdAt,
            ))
        .toList();
  }

  /// Set last sync timestamp
  Future<void> setLastSyncTime(DateTime time) async {
    await _database.setMetadata('last_sync', time.toIso8601String());
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final value = await _database.getMetadata('last_sync');
    if (value != null) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Clear completed sync operations
  Future<void> clearCompletedOperations() async {
    await _database.clearSyncedOperations();
  }

  /// Merge conflicts using last-write-wins strategy
  Map<String, dynamic> resolveConflictLastWriteWins(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // Simple last-write-wins: prefer remote if it's newer
    final localUpdated = DateTime.tryParse(local['lastUpdated']?.toString() ?? '');
    final remoteUpdated = DateTime.tryParse(remote['lastUpdated']?.toString() ?? '');

    if (remoteUpdated != null && localUpdated != null && remoteUpdated.isAfter(localUpdated)) {
      return remote;
    }
    return local;
  }

  /// Merge conflicts using manual resolution
  Map<String, dynamic> resolveConflictManual(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
    Map<String, dynamic>? userChoice,
  ) {
    if (userChoice != null) {
      return userChoice;
    }
    // Default to local if no user choice
    return local;
  }
}

/// Model for sync operation
class SyncOperation {
  final int id;
  final String farmId;
  final String operation; // 'create', 'update', 'delete'
  final String payload;
  final DateTime createdAt;
  final int retryCount;

  SyncOperation({
    required this.id,
    required this.farmId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
  });

  bool canRetry() => retryCount < 3; // Max 3 retries
}

/// Model for sync conflict
class SyncConflictData {
  final String id;
  final String farmId;
  final String localData;
  final String remoteData;
  final DateTime createdAt;

  SyncConflictData({
    required this.id,
    required this.farmId,
    required this.localData,
    required this.remoteData,
    required this.createdAt,
  });
}
