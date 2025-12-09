import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:crop_ai/features/offline_sync/data/database/drift_schema.dart';
import 'package:crop_ai/features/farm/models/farm.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Farms, SyncQueue, SyncConflicts, SyncMetadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  // ==================== Farm Operations ====================

  /// Get all non-deleted farms
  Future<List<Farm>> getAllFarms() async {
    final rows = await (select(farms)..where((tbl) => tbl.isDeleted.equals(false))).get();
    return rows.map(_farmFromRow).toList();
  }

  /// Get farm by ID
  Future<Farm?> getFarmById(String id) async {
    final row = await (select(farms)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row != null ? _farmFromRow(row) : null;
  }

  /// Insert or update farm (upsert)
  Future<void> insertFarm(Farm farm) async {
    await into(farms).insert(
      FarmsCompanion(
        id: Value(farm.id),
        name: Value(farm.name),
        latitude: Value(farm.latitude),
        longitude: Value(farm.longitude),
        areaHectares: Value(farm.areaHectares),
        cropType: Value(farm.cropType),
        plantingDate: Value(farm.plantingDate),
        expectedHarvestDate: Value(farm.expectedHarvestDate),
        healthStatus: Value(farm.healthStatus),
        soilMoisture: Value(farm.soilMoisture),
        temperature: Value(farm.temperature),
        lastUpdated: Value(farm.lastUpdated),
        createdAt: Value(DateTime.now()),
        isSynced: const Value(false),
        isDeleted: const Value(false),
      ),
      onConflict: DoUpdate((old) => FarmsCompanion(
        name: Value(farm.name),
        latitude: Value(farm.latitude),
        longitude: Value(farm.longitude),
        areaHectares: Value(farm.areaHectares),
        cropType: Value(farm.cropType),
        plantingDate: Value(farm.plantingDate),
        expectedHarvestDate: Value(farm.expectedHarvestDate),
        healthStatus: Value(farm.healthStatus),
        soilMoisture: Value(farm.soilMoisture),
        temperature: Value(farm.temperature),
        lastUpdated: Value(farm.lastUpdated),
        isSynced: const Value(false),
      )),
    );
  }

  /// Soft delete farm
  Future<void> deleteFarm(String id) async {
    await (update(farms)..where((tbl) => tbl.id.equals(id))).write(
      const FarmsCompanion(isDeleted: Value(true)),
    );
  }

  // ==================== Sync Queue Operations ====================

  /// Add operation to sync queue
  Future<int> queueOperation(String farmId, String operation, Map<String, dynamic> payload) async {
    return into(syncQueue).insert(
      SyncQueueCompanion(
        farmId: Value(farmId),
        operation: Value(operation),
        payload: Value(jsonEncode(payload)),
        createdAt: Value(DateTime.now()),
        retryCount: const Value(0),
      ),
    );
  }

  /// Get pending sync operations
  Future<List<SyncQueueData>> getPendingSyncOperations() async {
    final rows = await (select(syncQueue)..where((tbl) => tbl.isSynced.equals(false))).get();
    return rows;
  }

  /// Mark operation as synced
  Future<void> markOperationSynced(int queueId) async {
    await (update(syncQueue)..where((tbl) => tbl.id.equals(queueId))).write(
      SyncQueueCompanion(
        isSynced: const Value(true),
        attemptedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update sync operation retry count and error
  Future<void> updateSyncRetry(int queueId, String? error) async {
    await (update(syncQueue)..where((tbl) => tbl.id.equals(queueId))).write(
      SyncQueueCompanion(
        retryCount: syncQueue.retryCount + 1,
        error: Value(error),
        attemptedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Clear synced operations
  Future<void> clearSyncedOperations() async {
    await (delete(syncQueue)..where((tbl) => tbl.isSynced.equals(true))).go();
  }

  // ==================== Conflict Resolution ====================

  /// Create conflict record
  Future<void> createConflict(
    String id,
    String farmId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    await into(syncConflicts).insert(
      SyncConflictsCompanion(
        id: Value(id),
        farmId: Value(farmId),
        localData: Value(jsonEncode(localData)),
        remoteData: Value(jsonEncode(remoteData)),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  /// Resolve conflict
  Future<void> resolveConflict(String conflictId, String resolution) async {
    await (update(syncConflicts)..where((tbl) => tbl.id.equals(conflictId))).write(
      SyncConflictsCompanion(
        resolution: Value(resolution),
        resolvedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get unresolved conflicts
  Future<List<SyncConflictsData>> getUnresolvedConflicts() async {
    final rows = await (select(syncConflicts)..where((tbl) => tbl.resolution.isNull())).get();
    return rows;
  }

  // ==================== Metadata ====================

  /// Get metadata value
  Future<String?> getMetadata(String key) async {
    final row = await (select(syncMetadata)..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Set metadata value
  Future<void> setMetadata(String key, String value) async {
    await into(syncMetadata).insert(
      SyncMetadataCompanion(
        key: Value(key),
        value: Value(value),
        lastUpdated: Value(DateTime.now()),
      ),
      onConflict: DoUpdate((old) => SyncMetadataCompanion(
        value: Value(value),
        lastUpdated: Value(DateTime.now()),
      )),
    );
  }

  // ==================== Helper Methods ====================

  /// Convert database row to Farm model
  Farm _farmFromRow(FarmsData row) {
    return Farm(
      id: row.id,
      name: row.name,
      latitude: row.latitude,
      longitude: row.longitude,
      areaHectares: row.areaHectares,
      cropType: row.cropType,
      plantingDate: row.plantingDate,
      expectedHarvestDate: row.expectedHarvestDate,
      healthStatus: row.healthStatus,
      soilMoisture: row.soilMoisture,
      temperature: row.temperature,
      lastUpdated: row.lastUpdated,
    );
  }
}
