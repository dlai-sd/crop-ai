import 'package:flutter_riverpod/flutter_riverpod.dart';

// Sync status states
enum SyncStatus { idle, syncing, synced, error, offline }

// Sync provider - tracks online/offline state
final syncStatusProvider =
    StateNotifierProvider<SyncNotifier, SyncStatus>((ref) {
  return SyncNotifier();
});

class SyncNotifier extends StateNotifier<SyncStatus> {
  SyncNotifier() : super(SyncStatus.idle);

  void setSyncing() => state = SyncStatus.syncing;
  void setSynced() => state = SyncStatus.synced;
  void setError() => state = SyncStatus.error;
  void setOffline() => state = SyncStatus.offline;
  void reset() => state = SyncStatus.idle;

  Future<void> performSync() async {
    try {
      setSyncing();
      // Simulate sync operation
      await Future.delayed(const Duration(seconds: 2));
      setSynced();
      // Auto-reset after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      reset();
    } catch (e) {
      setError();
    }
  }
}

// Last sync time provider
final lastSyncTimeProvider =
    StateNotifierProvider<LastSyncNotifier, DateTime?>((ref) {
  return LastSyncNotifier();
});

class LastSyncNotifier extends StateNotifier<DateTime?> {
  LastSyncNotifier() : super(null);

  void updateLastSync() => state = DateTime.now();
  void reset() => state = null;
}
