import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:crop_ai/features/cloud_sync/models/cloud_sync_state.dart';
import 'package:crop_ai/features/cloud_sync/data/firebase_config.dart';
import 'dart:async';

/// Real Firebase repository implementation
class FirebaseRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;
  final RealtimeListenerManager _listenerManager = RealtimeListenerManager();

  FirebaseRepository({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseConfig.firestore,
        _auth = auth ?? FirebaseConfig.auth;

  // ==================== Authentication ====================

  /// Sign up with email and password
  Future<CloudUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Update profile
      await user.updateDisplayName(displayName);
      await user.reload();

      // Create user document in Firestore
      final cloudUser = CloudUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName,
        photoUrl: user.photoURL ?? '',
        createdAt: DateTime.now(),
        lastSignIn: DateTime.now(),
        emailVerified: false,
      );

      await _saveUserToFirestore(cloudUser);

      return cloudUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw FirebaseAuthException(e.message ?? 'Sign up failed');
    } catch (e) {
      throw FirebaseAuthException('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<CloudUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      final cloudUser = await _getUserFromFirestore(user.uid);

      // Update last sign in
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .update({'lastSignIn': FieldValue.serverTimestamp()});

      return cloudUser ??
          CloudUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            photoUrl: user.photoURL ?? '',
            createdAt: DateTime.now(),
            lastSignIn: DateTime.now(),
            emailVerified: user.emailVerified,
          );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw FirebaseAuthException(e.message ?? 'Sign in failed');
    } catch (e) {
      throw FirebaseAuthException('Sign in failed: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      _listenerManager.removeAllListeners();
      await _auth.signOut();
    } catch (e) {
      throw FirebaseAuthException('Sign out failed: $e');
    }
  }

  /// Get current authenticated user
  Future<CloudUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _getUserFromFirestore(user.uid);
  }

  // ==================== User Management ====================

  /// Save user to Firestore
  Future<void> _saveUserToFirestore(CloudUser user) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'emailVerified': user.emailVerified,
      });
    } catch (e) {
      throw FirebaseAuthException('Failed to save user: $e');
    }
  }

  /// Get user from Firestore
  Future<CloudUser?> _getUserFromFirestore(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return CloudUser(
        uid: data['uid'] as String,
        email: data['email'] as String,
        displayName: data['displayName'] as String? ?? '',
        photoUrl: data['photoUrl'] as String? ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastSignIn: (data['lastSignIn'] as Timestamp?)?.toDate() ?? DateTime.now(),
        emailVerified: data['emailVerified'] as bool? ?? false,
      );
    } catch (e) {
      throw FirebaseAuthException('Failed to fetch user: $e');
    }
  }

  /// Create farm in Firestore
  Future<CloudFarm> createFarm({
    required String userId,
    required String name,
    required String location,
    required double areaHectares,
    required String cropType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final farmId = _firestore.collection(FirebaseCollections.farms).doc().id;

      final farm = CloudFarm(
        id: farmId,
        userId: userId,
        name: name,
        location: location,
        areaHectares: areaHectares,
        cropType: cropType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: metadata ?? {},
        version: 1,
        isShared: false,
        sharedWith: [],
      );

      // Save to Firestore
      await _firestore
          .collection(FirebaseCollections.userFarmsCollection(userId).path)
          .doc(farmId)
          .set({
        'id': farm.id,
        'userId': farm.userId,
        'name': farm.name,
        'location': farm.location,
        'areaHectares': farm.areaHectares,
        'cropType': farm.cropType,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': farm.metadata,
        'version': farm.version,
        'isShared': farm.isShared,
        'sharedWith': farm.sharedWith,
      });

      return farm;
    } catch (e) {
      throw FirebaseAuthException('Failed to create farm: $e');
    }
  }

  /// Get farm by ID
  Future<CloudFarm?> getFarm(String userId, String farmId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.userFarmsCollection(userId).path)
          .doc(farmId)
          .get();

      return doc.exists ? _mapToCloudFarm(doc) : null;
    } catch (e) {
      throw FirebaseAuthException('Failed to fetch farm: $e');
    }
  }

  /// Get all farms for user
  Future<List<CloudFarm>> getUserFarms(String userId) async {
    try {
      final query = await _firestore
          .collection(FirebaseCollections.userFarmsCollection(userId).path)
          .orderBy('updatedAt', descending: true)
          .get();

      return query.docs.map((doc) => _mapToCloudFarm(doc)).toList();
    } catch (e) {
      throw FirebaseAuthException('Failed to fetch farms: $e');
    }
  }

  /// Update farm
  Future<CloudFarm> updateFarm(CloudFarm farm) async {
    try {
      final updatedFarm = farm.copyWith(
        updatedAt: DateTime.now(),
        version: farm.version + 1,
      );

      await _firestore
          .collection(FirebaseCollections.userFarmsCollection(farm.userId).path)
          .doc(farm.id)
          .update({
        'name': updatedFarm.name,
        'location': updatedFarm.location,
        'areaHectares': updatedFarm.areaHectares,
        'cropType': updatedFarm.cropType,
        'metadata': updatedFarm.metadata,
        'updatedAt': FieldValue.serverTimestamp(),
        'version': updatedFarm.version,
      });

      return updatedFarm;
    } catch (e) {
      throw FirebaseAuthException('Failed to update farm: $e');
    }
  }

  /// Delete farm
  Future<void> deleteFarm(String userId, String farmId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.userFarmsCollection(userId).path)
          .doc(farmId)
          .delete();
    } catch (e) {
      throw FirebaseAuthException('Failed to delete farm: $e');
    }
  }

  /// Share farm with another user
  Future<void> shareFarm({
    required String userId,
    required String farmId,
    required String shareWithUserId,
  }) async {
    try {
      final batch = FirestoreBatchHelper.createBatch();

      // Update farm sharing list
      final farmRef = _firestore
          .collection(FirebaseCollections.userFarmsCollection(userId).path)
          .doc(farmId);

      batch.update(farmRef, {
        'sharedWith': FieldValue.arrayUnion([shareWithUserId]),
      });

      // Create association document
      final assocRef = FirebaseCollections.userFarmAssoc(shareWithUserId, farmId);
      batch.set(assocRef, {
        'userId': shareWithUserId,
        'farmId': farmId,
        'associatedAt': FieldValue.serverTimestamp(),
        'accessLevel': 'viewer',
      });

      await FirestoreBatchHelper.commitBatch(batch);
    } catch (e) {
      throw FirebaseAuthException('Failed to share farm: $e');
    }
  }

  /// Upload sync events
  Future<void> uploadSyncEventsBatch(List<SyncEvent> events) async {
    try {
      final batch = FirestoreBatchHelper.createBatch();

      for (var event in events) {
        final docRef = _firestore
            .collection(FirebaseCollections.syncLogs)
            .doc(event.id);

        batch.set(docRef, {
          'id': event.id,
          'entityType': event.entityType,
          'entityId': event.entityId,
          'eventType': event.eventType.toString(),
          'data': event.data,
          'createdAt': Timestamp.fromDate(event.createdAt),
          'syncedAt': Timestamp.fromDate(DateTime.now()),
          'conflictResolution': event.conflictResolution,
        });
      }

      await FirestoreBatchHelper.commitBatch(batch);
    } catch (e) {
      throw FirebaseAuthException('Failed to upload sync events: $e');
    }
  }

  /// Download sync events (changes from cloud)
  Future<List<SyncEvent>> downloadSyncEvents({
    required String farmId,
    required DateTime since,
  }) async {
    try {
      final query = await _firestore
          .collection(FirebaseCollections.syncLogs)
          .where('entityId', isEqualTo: farmId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => _mapToSyncEvent(doc.data()))
          .toList();
    } catch (e) {
      throw FirebaseAuthException('Failed to download sync events: $e');
    }
  }

  /// Get sync conflicts for farm
  Future<List<SyncConflict>> getSyncConflicts(String farmId) async {
    try {
      final query = await _firestore
          .collectionGroup('conflicts')
          .where('entityId', isEqualTo: farmId)
          .where('resolvedAt', isEqualTo: null)
          .get();

      return query.docs
          .map((doc) => _mapToSyncConflict(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseAuthException('Failed to fetch conflicts: $e');
    }
  }

  /// Get last sync timestamp for farm
  Future<DateTime?> getLastSyncTime(String farmId) async {
    try {
      final query = await _firestore
          .collection(FirebaseCollections.syncLogs)
          .where('entityId', isEqualTo: farmId)
          .orderBy('syncedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final timestamp = query.docs.first['syncedAt'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      throw FirebaseAuthException('Failed to get last sync time: $e');
    }
  }

  // ==================== Helper Methods ====================

  CloudFarm _mapToCloudFarm(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CloudFarm(
      id: data['id'] as String,
      userId: data['userId'] as String,
      name: data['name'] as String,
      location: data['location'] as String,
      areaHectares: (data['areaHectares'] as num).toDouble(),
      cropType: data['cropType'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
      version: data['version'] as int? ?? 1,
      isShared: data['isShared'] as bool? ?? false,
      sharedWith: List<String>.from(data['sharedWith'] as List? ?? []),
    );
  }

  SyncEvent _mapToSyncEvent(Map<String, dynamic> data) {
    return SyncEvent(
      id: data['id'] as String,
      entityType: data['entityType'] as String,
      entityId: data['entityId'] as String,
      eventType: _parseSyncEventType(data['eventType'] as String),
      data: (data['data'] as Map<String, dynamic>?) ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      syncedAt: (data['syncedAt'] as Timestamp?)?.toDate(),
      isUploaded: true,
      conflictResolution: data['conflictResolution'] as String?,
    );
  }

  SyncConflict _mapToSyncConflict(Map<String, dynamic> data) {
    return SyncConflict(
      id: data['id'] as String,
      entityType: data['entityType'] as String,
      entityId: data['entityId'] as String,
      localVersion: (data['localVersion'] as Map<String, dynamic>?) ?? {},
      remoteVersion: (data['remoteVersion'] as Map<String, dynamic>?) ?? {},
      detectedAt: (data['detectedAt'] as Timestamp).toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolution: data['resolution'] as String?,
      mergedVersion: data['mergedVersion'] as Map<String, dynamic>?,
    );
  }

  SyncEventType _parseSyncEventType(String value) {
    return SyncEventType.values.firstWhere(
      (e) => e.toString().contains(value),
      orElse: () => SyncEventType.update,
    );
  }
}

// ==================== Custom Exceptions ====================

class FirebaseAuthException implements Exception {
  final String message;
  FirebaseAuthException(this.message);

  @override
  String toString() => message;
}
