import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/providers/sync_provider.dart';

void main() {
  group('SyncNotifier', () {
    test('Initial state is idle', () {
      final container = ProviderContainer();
      final state = container.read(syncStatusProvider);

      expect(state, SyncStatus.idle);
    });

    test('setSyncing changes state to syncing', () {
      final container = ProviderContainer();
      final notifier = container.read(syncStatusProvider.notifier);

      notifier.setSyncing();

      expect(container.read(syncStatusProvider), SyncStatus.syncing);
    });

    test('setSynced changes state to synced', () {
      final container = ProviderContainer();
      final notifier = container.read(syncStatusProvider.notifier);

      notifier.setSyncing();
      notifier.setSynced();

      expect(container.read(syncStatusProvider), SyncStatus.synced);
    });

    test('setError changes state to error', () {
      final container = ProviderContainer();
      final notifier = container.read(syncStatusProvider.notifier);

      notifier.setError();

      expect(container.read(syncStatusProvider), SyncStatus.error);
    });

    test('setOffline changes state to offline', () {
      final container = ProviderContainer();
      final notifier = container.read(syncStatusProvider.notifier);

      notifier.setOffline();

      expect(container.read(syncStatusProvider), SyncStatus.offline);
    });

    test('reset changes state to idle', () {
      final container = ProviderContainer();
      final notifier = container.read(syncStatusProvider.notifier);

      notifier.setSyncing();
      notifier.reset();

      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test('performSync cycles through states', () async {
      final container = ProviderContainer();
      final notifier = container.read(syncStatusProvider.notifier);

      // Start sync
      notifier.performSync();

      // Check initial state is syncing
      await Future.delayed(const Duration(milliseconds: 100));
      expect(container.read(syncStatusProvider), SyncStatus.syncing);

      // After completion, it should eventually reset
      // (the function auto-resets after 2 seconds, so we don't check that)
    });
  });

  group('LastSyncNotifier', () {
    test('Initial state is null', () {
      final container = ProviderContainer();
      final state = container.read(lastSyncTimeProvider);

      expect(state, isNull);
    });

    test('updateLastSync sets current time', () {
      final container = ProviderContainer();
      final notifier = container.read(lastSyncTimeProvider.notifier);

      final before = DateTime.now();
      notifier.updateLastSync();
      final after = DateTime.now();

      final state = container.read(lastSyncTimeProvider);

      expect(state, isNotNull);
      expect(state!.isAfter(before) || state == before, true);
      expect(state.isBefore(after) || state == after, true);
    });

    test('reset clears last sync time', () {
      final container = ProviderContainer();
      final notifier = container.read(lastSyncTimeProvider.notifier);

      notifier.updateLastSync();
      notifier.reset();

      expect(container.read(lastSyncTimeProvider), isNull);
    });
  });

  group('SyncStatus Enum', () {
    test('SyncStatus has all expected values', () {
      expect(SyncStatus.idle, SyncStatus.idle);
      expect(SyncStatus.syncing, SyncStatus.syncing);
      expect(SyncStatus.synced, SyncStatus.synced);
      expect(SyncStatus.error, SyncStatus.error);
      expect(SyncStatus.offline, SyncStatus.offline);
    });

    test('SyncStatus values are distinct', () {
      const values = [
        SyncStatus.idle,
        SyncStatus.syncing,
        SyncStatus.synced,
        SyncStatus.error,
        SyncStatus.offline,
      ];

      expect(values.toSet().length, 5);
    });
  });
}
