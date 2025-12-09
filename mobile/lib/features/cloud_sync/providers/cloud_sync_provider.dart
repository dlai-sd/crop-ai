import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/cloud_sync/models/cloud_sync_state.dart';
import 'package:crop_ai/features/cloud_sync/data/firebase_repository.dart';
import 'package:crop_ai/features/cloud_sync/data/offline_cache_service.dart';
import 'package:crop_ai/features/cloud_sync/data/sync_manager.dart';

// Repositories
final firebaseRepositoryProvider = Provider((ref) => FirebaseRepository());

final offlineCacheProvider = Provider((ref) => OfflineCacheService());

final syncManagerProvider = Provider((ref) {
  final firebase = ref.watch(firebaseRepositoryProvider);
  final cache = ref.watch(offlineCacheProvider);
  return SyncManager(firebaseRepository: firebase, offlineCache: cache);
});

// Authentication state
final currentUserProvider = FutureProvider<CloudUser?>((ref) async {
  final firebase = ref.watch(firebaseRepositoryProvider);
  return firebase.getCurrentUser();
});

final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user != null;
});

// User farms
final userFarmsProvider = FutureProvider.family<List<CloudFarm>, String>((ref, userId) async {
  final firebase = ref.watch(firebaseRepositoryProvider);
  return firebase.getUserFarms(userId);
});

final userFarmsCachedProvider =
    FutureProvider.family<List<CloudFarm>, String>((ref, userId) async {
  final cache = ref.watch(offlineCacheProvider);
  return cache.getCachedFarmsForUser(userId);
});

// Sync state
final syncStateProvider = StateProvider<CloudSyncState>((ref) {
  return CloudSyncState(status: SyncStatus.idle);
});

// Sync statistics for farm
final syncStatisticsProvider =
    FutureProvider.family<SyncStatistics, String>((ref, farmId) async {
  final manager = ref.watch(syncManagerProvider);
  return manager.getSyncStatistics(farmId);
});

// Pending sync events for farm
final pendingSyncEventsProvider =
    FutureProvider.family<List<SyncEvent>, String>((ref, farmId) async {
  final cache = ref.watch(offlineCacheProvider);
  return cache.getPendingEventsForFarm(farmId);
});

// Unresolved conflicts for farm
final unresolvedConflictsProvider =
    FutureProvider.family<List<SyncConflict>, String>((ref, farmId) async {
  final firebase = ref.watch(firebaseRepositoryProvider);
  return firebase.getSyncConflicts(farmId);
});

// Selected farm for sync operations
final selectedFarmForSyncProvider = StateProvider<String?>((ref) {
  return null;
});

// Sync in progress indicator
final isSyncingProvider = StateProvider<bool>((ref) {
  return false;
});

// Last sync time for farm
final lastSyncTimeProvider =
    FutureProvider.family<DateTime?, String>((ref, farmId) async {
  final firebase = ref.watch(firebaseRepositoryProvider);
  return firebase.getLastSyncTime(farmId);
});

// Sign up use case
Future<CloudUser> Function(String, String, String) _signUpUseCase(WidgetRef ref) {
  return (email, password, displayName) {
    final firebase = ref.watch(firebaseRepositoryProvider);
    return firebase.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  };
}

// Sign in use case
Future<CloudUser> Function(String, String) _signInUseCase(WidgetRef ref) {
  return (email, password) {
    final firebase = ref.watch(firebaseRepositoryProvider);
    return firebase.signIn(email: email, password: password);
  };
}

// Sync farm use case
Future<void> Function(String) _syncFarmUseCase(WidgetRef ref) {
  return (farmId) async {
    final manager = ref.watch(syncManagerProvider);
    ref.watch(isSyncingProvider.notifier).state = true;

    try {
      await manager.syncFarm(farmId);
      ref.invalidate(syncStatisticsProvider(farmId));
      ref.invalidate(pendingSyncEventsProvider(farmId));
      ref.invalidate(lastSyncTimeProvider(farmId));
    } finally {
      ref.watch(isSyncingProvider.notifier).state = false;
    }
  };
}

// Create farm use case
Future<CloudFarm> Function({
  required String userId,
  required String name,
  required String location,
  required double areaHectares,
  required String cropType,
}) _createFarmUseCase(WidgetRef ref) {
  return ({
    required String userId,
    required String name,
    required String location,
    required double areaHectares,
    required String cropType,
  }) async {
    final firebase = ref.watch(firebaseRepositoryProvider);
    final farm = await firebase.createFarm(
      userId: userId,
      name: name,
      location: location,
      areaHectares: areaHectares,
      cropType: cropType,
    );

    // Cache locally
    final cache = ref.watch(offlineCacheProvider);
    await cache.cacheFarm(farm);

    // Invalidate farms list
    ref.invalidate(userFarmsProvider(userId));

    return farm;
  };
}

// Queue change use case
Future<void> Function({
  required String farmId,
  required String entityType,
  required String entityId,
  required Map<String, dynamic> data,
  required SyncEventType eventType,
}) _queueChangeUseCase(WidgetRef ref) {
  return ({
    required String farmId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    required SyncEventType eventType,
  }) async {
    final manager = ref.watch(syncManagerProvider);
    await manager.queueLocalChange(
      entityType: entityType,
      entityId: entityId,
      data: data,
      eventType: eventType,
    );

    // Invalidate pending events
    ref.invalidate(pendingSyncEventsProvider(farmId));
    ref.invalidate(syncStatisticsProvider(farmId));
  };
}

// Export use cases as providers
final signUpUseCaseProvider = Provider((ref) => _signUpUseCase(ref));
final signInUseCaseProvider = Provider((ref) => _signInUseCase(ref));
final syncFarmUseCaseProvider = Provider((ref) => _syncFarmUseCase(ref));
final createFarmUseCaseProvider = Provider((ref) => _createFarmUseCase(ref));
final queueChangeUseCaseProvider = Provider((ref) => _queueChangeUseCase(ref));
