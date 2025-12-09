import 'package:drift/drift.dart';

// Define the farms table
class Farms extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get areaHectares => real()();
  TextColumn get cropType => text()();
  DateTimeColumn get plantingDate => dateTime()();
  DateTimeColumn get expectedHarvestDate => dateTime().nullable()();
  TextColumn get healthStatus => text()();
  RealColumn get soilMoisture => real()();
  RealColumn get temperature => real()();
  DateTimeColumn get lastUpdated => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get photoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Define the sync queue table for offline operations
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get farmId => text()();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get payload => text()(); // JSON string of data
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get attemptedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get error => text().nullable()();
}

// Define the conflict resolution table
class SyncConflicts extends Table {
  TextColumn get id => text()();
  TextColumn get farmId => text()();
  TextColumn get localData => text()(); // JSON
  TextColumn get remoteData => text()(); // JSON
  TextColumn get resolution => text().nullable()(); // 'local', 'remote', 'manual'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
}

// Define the metadata table for sync state
class SyncMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
