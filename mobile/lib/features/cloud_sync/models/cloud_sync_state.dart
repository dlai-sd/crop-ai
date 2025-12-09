/// Sync status for cloud operations
enum SyncStatus { idle, syncing, success, error, offline }

/// Direction of sync operation
enum SyncDirection { upload, download, bidirectional }

/// Cloud sync state model
class CloudSyncState {
  final SyncStatus status;
  final String? message;
  final int pendingChanges; // Changes waiting to sync
  final int totalChanges; // Total changes in queue
  final DateTime? lastSyncTime;
  final SyncDirection direction;
  final bool isOnline;
  final String? errorCode;

  CloudSyncState({
    required this.status,
    this.message,
    this.pendingChanges = 0,
    this.totalChanges = 0,
    this.lastSyncTime,
    this.direction = SyncDirection.bidirectional,
    this.isOnline = true,
    this.errorCode,
  });

  /// Copy with modified fields
  CloudSyncState copyWith({
    SyncStatus? status,
    String? message,
    int? pendingChanges,
    int? totalChanges,
    DateTime? lastSyncTime,
    SyncDirection? direction,
    bool? isOnline,
    String? errorCode,
  }) {
    return CloudSyncState(
      status: status ?? this.status,
      message: message ?? this.message,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      totalChanges: totalChanges ?? this.totalChanges,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      direction: direction ?? this.direction,
      isOnline: isOnline ?? this.isOnline,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  /// Progress percentage (0-100)
  int get progressPercentage {
    if (totalChanges == 0) return 0;
    return ((totalChanges - pendingChanges) / totalChanges * 100).toInt();
  }

  /// Whether sync is in progress
  bool get isSyncing => status == SyncStatus.syncing;

  /// Whether last sync was successful
  bool get isSuccessful => status == SyncStatus.success;

  /// Whether there are pending changes
  bool get hasPendingChanges => pendingChanges > 0;

  Map<String, dynamic> toMap() => {
        'status': status.toString(),
        'message': message,
        'pendingChanges': pendingChanges,
        'totalChanges': totalChanges,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
        'direction': direction.toString(),
        'isOnline': isOnline,
        'errorCode': errorCode,
      };
}

/// Sync event for individual entity changes
class SyncEvent {
  final String id;
  final String entityType; // 'farm', 'prediction', 'recommendation', etc.
  final String entityId;
  final SyncEventType eventType;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final bool isUploaded;
  final String? conflictResolution; // 'local_wins', 'remote_wins', 'merged'

  SyncEvent({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.eventType,
    required this.data,
    required this.createdAt,
    this.syncedAt,
    this.isUploaded = false,
    this.conflictResolution,
  });

  factory SyncEvent.create(
    String entityType,
    String entityId,
    Map<String, dynamic> data,
  ) {
    return SyncEvent(
      id: '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      eventType: SyncEventType.create,
      data: data,
      createdAt: DateTime.now(),
    );
  }

  factory SyncEvent.update(
    String entityType,
    String entityId,
    Map<String, dynamic> data,
  ) {
    return SyncEvent(
      id: '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      eventType: SyncEventType.update,
      data: data,
      createdAt: DateTime.now(),
    );
  }

  factory SyncEvent.delete(String entityType, String entityId) {
    return SyncEvent(
      id: '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      eventType: SyncEventType.delete,
      data: {'deletedAt': DateTime.now().toIso8601String()},
      createdAt: DateTime.now(),
    );
  }

  SyncEvent markAsSynced() {
    return SyncEvent(
      id: id,
      entityType: entityType,
      entityId: entityId,
      eventType: eventType,
      data: data,
      createdAt: createdAt,
      syncedAt: DateTime.now(),
      isUploaded: true,
      conflictResolution: conflictResolution,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'eventType': eventType.toString(),
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'syncedAt': syncedAt?.toIso8601String(),
        'isUploaded': isUploaded,
        'conflictResolution': conflictResolution,
      };

  factory SyncEvent.fromMap(Map<String, dynamic> map) {
    return SyncEvent(
      id: map['id'] as String,
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as String,
      eventType: SyncEventType.values.firstWhere(
        (e) => e.toString() == map['eventType'],
        orElse: () => SyncEventType.update,
      ),
      data: map['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(map['createdAt'] as String),
      syncedAt:
          map['syncedAt'] != null ? DateTime.parse(map['syncedAt'] as String) : null,
      isUploaded: map['isUploaded'] as bool? ?? false,
      conflictResolution: map['conflictResolution'] as String?,
    );
  }
}

enum SyncEventType { create, update, delete }

/// Sync conflict for version control
class SyncConflict {
  final String id;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> remoteVersion;
  final DateTime detectedAt;
  final DateTime? resolvedAt;
  final String? resolution; // 'local_wins', 'remote_wins', 'merged'
  final Map<String, dynamic>? mergedVersion;

  SyncConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localVersion,
    required this.remoteVersion,
    required this.detectedAt,
    this.resolvedAt,
    this.resolution,
    this.mergedVersion,
  });

  factory SyncConflict.detect(
    String entityType,
    String entityId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    return SyncConflict(
      id: '${entityType}_${entityId}_conflict',
      entityType: entityType,
      entityId: entityId,
      localVersion: localData,
      remoteVersion: remoteData,
      detectedAt: DateTime.now(),
    );
  }

  bool get isResolved => resolvedAt != null && resolution != null;

  SyncConflict resolveWithLocal() {
    return SyncConflict(
      id: id,
      entityType: entityType,
      entityId: entityId,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      detectedAt: detectedAt,
      resolvedAt: DateTime.now(),
      resolution: 'local_wins',
      mergedVersion: localVersion,
    );
  }

  SyncConflict resolveWithRemote() {
    return SyncConflict(
      id: id,
      entityType: entityType,
      entityId: entityId,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      detectedAt: detectedAt,
      resolvedAt: DateTime.now(),
      resolution: 'remote_wins',
      mergedVersion: remoteVersion,
    );
  }

  SyncConflict resolveWithMerge(Map<String, dynamic> merged) {
    return SyncConflict(
      id: id,
      entityType: entityType,
      entityId: entityId,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      detectedAt: detectedAt,
      resolvedAt: DateTime.now(),
      resolution: 'merged',
      mergedVersion: merged,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'localVersion': localVersion,
        'remoteVersion': remoteVersion,
        'detectedAt': detectedAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'resolution': resolution,
        'mergedVersion': mergedVersion,
      };
}

/// Cloud user profile
class CloudUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final DateTime createdAt;
  final DateTime lastSignIn;
  final bool emailVerified;
  final List<String> farmsOwned; // Farm IDs
  final List<String> farmsShared; // Farm IDs shared with user

  CloudUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    required this.createdAt,
    required this.lastSignIn,
    this.emailVerified = false,
    this.farmsOwned = const [],
    this.farmsShared = const [],
  });

  factory CloudUser.fromFirebaseUser({
    required String uid,
    required String email,
    String displayName = '',
    String photoUrl = '',
  }) {
    final now = DateTime.now();
    return CloudUser(
      uid: uid,
      email: email,
      displayName: displayName.isEmpty ? email.split('@')[0] : displayName,
      photoUrl: photoUrl,
      createdAt: now,
      lastSignIn: now,
      emailVerified: false,
      farmsOwned: [],
      farmsShared: [],
    );
  }

  CloudUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastSignIn,
    bool? emailVerified,
    List<String>? farmsOwned,
    List<String>? farmsShared,
  }) {
    return CloudUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      emailVerified: emailVerified ?? this.emailVerified,
      farmsOwned: farmsOwned ?? this.farmsOwned,
      farmsShared: farmsShared ?? this.farmsShared,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
        'lastSignIn': lastSignIn.toIso8601String(),
        'emailVerified': emailVerified,
        'farmsOwned': farmsOwned,
        'farmsShared': farmsShared,
      };

  factory CloudUser.fromMap(Map<String, dynamic> map) {
    return CloudUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastSignIn: DateTime.parse(map['lastSignIn'] as String),
      emailVerified: map['emailVerified'] as bool? ?? false,
      farmsOwned: List<String>.from(map['farmsOwned'] as List? ?? []),
      farmsShared: List<String>.from(map['farmsShared'] as List? ?? []),
    );
  }
}

/// Farm document for cloud storage
class CloudFarm {
  final String id;
  final String userId; // Owner ID
  final String name;
  final String location;
  final double areaHectares;
  final String cropType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final int version; // For conflict detection
  final bool isShared;
  final List<String> sharedWith; // User IDs with access

  CloudFarm({
    required this.id,
    required this.userId,
    required this.name,
    required this.location,
    required this.areaHectares,
    required this.cropType,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
    this.version = 1,
    this.isShared = false,
    this.sharedWith = const [],
  });

  factory CloudFarm.create({
    required String userId,
    required String name,
    required String location,
    required double areaHectares,
    required String cropType,
  }) {
    final now = DateTime.now();
    return CloudFarm(
      id: 'farm_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: name,
      location: location,
      areaHectares: areaHectares,
      cropType: cropType,
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  CloudFarm copyWith({
    String? id,
    String? userId,
    String? name,
    String? location,
    double? areaHectares,
    String? cropType,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    int? version,
    bool? isShared,
    List<String>? sharedWith,
  }) {
    return CloudFarm(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      location: location ?? this.location,
      areaHectares: areaHectares ?? this.areaHectares,
      cropType: cropType ?? this.cropType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      version: version ?? this.version,
      isShared: isShared ?? this.isShared,
      sharedWith: sharedWith ?? this.sharedWith,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'location': location,
        'areaHectares': areaHectares,
        'cropType': cropType,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'metadata': metadata,
        'version': version,
        'isShared': isShared,
        'sharedWith': sharedWith,
      };

  factory CloudFarm.fromMap(Map<String, dynamic> map) {
    return CloudFarm(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      location: map['location'] as String,
      areaHectares: (map['areaHectares'] as num).toDouble(),
      cropType: map['cropType'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
      version: map['version'] as int? ?? 1,
      isShared: map['isShared'] as bool? ?? false,
      sharedWith: List<String>.from(map['sharedWith'] as List? ?? []),
    );
  }
}
