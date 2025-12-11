import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Local SQLite database for offline-first sync
/// Stores: Users, Farms, Conversations, Sync metadata

// ============================================================================
// Database Tables
// ============================================================================

/// Cached user profile from backend
@DataClassName('UserModel')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().unique()();
  TextColumn get email => text()();
  TextColumn get name => text()();
  TextColumn get profilePictureUrl => text().nullable()();
  TextColumn get role => text()(); // farmer, partner, customer
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Cached farm profiles
@DataClassName('FarmModel')
class Farms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get farmId => text().unique()();
  IntColumn get userId => integer()();
  TextColumn get name => text()();
  TextColumn get location => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get areaAcres => real().nullable()();
  TextColumn get cropType => text().nullable()();
  TextColumn get soilHealth => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Cached conversations between farmers
@DataClassName('ConversationModel')
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get conversationId => text().unique()();
  IntColumn get userId => integer()();
  TextColumn get participantUserId => text()();
  TextColumn get participantName => text()();
  TextColumn get participantProfilePictureUrl => text().nullable()();
  TextColumn get lastMessagePreview => text().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Cached messages in conversations
@DataClassName('MessageModel')
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text().unique()();
  IntColumn get conversationId => integer()();
  IntColumn get senderId => integer()();
  TextColumn get senderName => text()();
  TextColumn get content => text()();
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get mediaType => text().nullable()(); // photo, video, audio, text
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))(); // synced, pending, failed
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Offline sync queue for failed operations
@DataClassName('SyncQueueModel')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()(); // create, update, delete
  TextColumn get entityType => text()(); // message, farm, conversation
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON encoded
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, synced, failed
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

/// Metadata for sync tracking
@DataClassName('SyncMetadataModel')
class SyncMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  IntColumn get pendingChanges => integer().withDefault(const Constant(0))();
}

// ============================================================================
// Database Class
// ============================================================================

@DriftDatabase(
  tables: [
    Users,
    Farms,
    Conversations,
    Messages,
    SyncQueue,
    SyncMetadata,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  // ========================================================================
  // User Operations
  // ========================================================================

  Future<void> insertOrUpdateUser(UserModel user) async {
    await into(users).insertOnConflictUpdate(user);
  }

  Future<UserModel?> getUserById(String userId) async {
    return (select(users)..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<List<UserModel>> getAllUsers() async {
    return select(users).get();
  }

  // ========================================================================
  // Farm Operations
  // ========================================================================

  Future<void> insertOrUpdateFarm(FarmModel farm) async {
    await into(farms).insertOnConflictUpdate(farm);
  }

  Future<FarmModel?> getFarmById(String farmId) async {
    return (select(farms)..where((t) => t.farmId.equals(farmId)))
        .getSingleOrNull();
  }

  Future<List<FarmModel>> getFarmsByUser(int userId) async {
    return (select(farms)..where((t) => t.userId.equals(userId))).get();
  }

  Future<void> deleteFarm(String farmId) async {
    await (delete(farms)..where((t) => t.farmId.equals(farmId))).go();
  }

  // ========================================================================
  // Conversation Operations
  // ========================================================================

  Future<void> insertOrUpdateConversation(ConversationModel conversation) async {
    await into(conversations).insertOnConflictUpdate(conversation);
  }

  Future<List<ConversationModel>> getConversationsByUser(int userId) async {
    return (select(conversations)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm(expression: t.lastMessageAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<ConversationModel?> getConversationById(String conversationId) async {
    return (select(conversations)..where((t) => t.conversationId.equals(conversationId)))
        .getSingleOrNull();
  }

  // ========================================================================
  // Message Operations
  // ========================================================================

  Future<void> insertOrUpdateMessage(MessageModel message) async {
    await into(messages).insertOnConflictUpdate(message);
  }

  Future<List<MessageModel>> getMessagesByConversation(int conversationId) async {
    return (select(messages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // ========================================================================
  // Sync Queue Operations
  // ========================================================================

  Future<void> addToSyncQueue({
    required String operation,
    required String entityType,
    required String entityId,
    required String payload,
  }) async {
    await into(syncQueue).insert(
      SyncQueueCompanion(
        operation: Value(operation),
        entityType: Value(entityType),
        entityId: Value(entityId),
        payload: Value(payload),
        status: const Value('pending'),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<SyncQueueModel>> getPendingSyncItems() async {
    return (select(syncQueue)..where((t) => t.status.equals('pending')))
        .get();
  }

  Future<void> markSyncItemSynced(int id) async {
    await (update(syncQueue)..where((t) => t.id.equals(id)))
        .write(const SyncQueueCompanion(status: Value('synced')));
  }

  // ========================================================================
  // Metadata Operations
  // ========================================================================

  Future<void> updateSyncMetadata(
    DateTime syncAt,
    int pendingChanges,
  ) async {
    await into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataModel(
        id: 1, // Fixed ID for global sync metadata
        lastSyncAt: syncAt,
        syncStatus: 'synced',
        pendingChanges: pendingChanges,
      ),
    );
  }

  Future<SyncMetadataModel?> getSyncMetadata() async {
    return (select(syncMetadata)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  // ========================================================================
  // Bulk Operations
  // ========================================================================

  Future<void> clearAllData() async {
    await delete(messages).go();
    await delete(conversations).go();
    await delete(farms).go();
    await delete(users).go();
    await delete(syncQueue).go();
    await delete(syncMetadata).go();
  }
}
