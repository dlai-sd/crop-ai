import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/cloud_sync/data/firebase_connection_monitor.dart';

void main() {
  group('Firebase Connection Monitor Tests', () {
    late FirebaseConnectionMonitor monitor;

    setUp(() {
      monitor = FirebaseConnectionMonitor();
    });

    group('Connection Status Tracking', () {
      test('currentStatus returns checking when initialized', () {
        expect(
          monitor.currentStatus,
          equals(FirebaseConnectionStatus.checking),
        );
      });

      test('connectionStatusStream emits status changes', () {
        expect(
          monitor.connectionStatusStream,
          emits(FirebaseConnectionStatus.connected),
        );
      });
    });

    group('Sync Readiness', () {
      test('currentReadiness returns initial state', () {
        final readiness = monitor.currentReadiness;
        expect(readiness.isConnected, isFalse);
        expect(readiness.hasInternet, isFalse);
        expect(readiness.isFirebaseReady, isFalse);
      });

      test('isReadyToSync returns false when not connected', () {
        expect(monitor.isReadyToSync, isFalse);
      });

      test('syncReadinessStream emits readiness changes', () {
        expect(
          monitor.syncReadinessStream,
          emits(isA<SyncReadiness>()),
        );
      });
    });

    group('SyncReadiness Model', () {
      test('isReadyForSync requires all conditions', () {
        final readiness = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: true,
        );
        expect(readiness.isReadyForSync, isTrue);
      });

      test('isReadyForSync fails if any condition is false', () {
        final readiness1 = SyncReadiness(
          isConnected: false,
          hasInternet: true,
          isFirebaseReady: true,
        );
        expect(readiness1.isReadyForSync, isFalse);

        final readiness2 = SyncReadiness(
          isConnected: true,
          hasInternet: false,
          isFirebaseReady: true,
        );
        expect(readiness2.isReadyForSync, isFalse);

        final readiness3 = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: false,
        );
        expect(readiness3.isReadyForSync, isFalse);
      });

      test('statusDisplay shows appropriate message', () {
        final noInternet = SyncReadiness(
          isConnected: true,
          hasInternet: false,
          isFirebaseReady: true,
        );
        expect(noInternet.statusDisplay, contains('internet'));

        final firebaseNotReady = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: false,
        );
        expect(firebaseNotReady.statusDisplay, contains('Firebase'));

        final notConnected = SyncReadiness(
          isConnected: false,
          hasInternet: true,
          isFirebaseReady: true,
        );
        expect(notConnected.statusDisplay, contains('Firebase'));

        final ready = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: true,
        );
        expect(ready.statusDisplay, contains('Ready'));
      });

      test('uiStatus shows appropriate symbols', () {
        final ready = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: true,
        );
        expect(ready.uiStatus, contains('✓'));

        final offline = SyncReadiness(
          isConnected: true,
          hasInternet: false,
          isFirebaseReady: true,
        );
        expect(offline.uiStatus, contains('✗'));

        final initializing = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: false,
        );
        expect(initializing.uiStatus, contains('⟳'));
      });

      test('copyWith creates new instance with updates', () {
        final original = SyncReadiness(
          isConnected: true,
          hasInternet: false,
          isFirebaseReady: true,
        );

        final updated = original.copyWith(hasInternet: true);

        expect(original.hasInternet, isFalse);
        expect(updated.hasInternet, isTrue);
        expect(updated.isConnected, isTrue);
        expect(updated.isFirebaseReady, isTrue);
      });

      test('equality comparison works', () {
        final readiness1 = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: true,
        );

        final readiness2 = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: true,
        );

        final readiness3 = SyncReadiness(
          isConnected: false,
          hasInternet: true,
          isFirebaseReady: true,
        );

        expect(readiness1, equals(readiness2));
        expect(readiness1, isNot(equals(readiness3)));
      });

      test('hashCode consistency', () {
        final readiness1 = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: true,
        );

        final readiness2 = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: true,
        );

        expect(readiness1.hashCode, equals(readiness2.hashCode));
      });

      test('toMap serialization', () {
        final readiness = SyncReadiness(
          isConnected: true,
          hasInternet: true,
          isFirebaseReady: true,
        );

        final map = readiness.toMap();

        expect(map['isConnected'], isTrue);
        expect(map['hasInternet'], isTrue);
        expect(map['isFirebaseReady'], isTrue);
        expect(map['isReadyForSync'], isTrue);
        expect(map['statusDisplay'], isNotEmpty);
        expect(map['uiStatus'], isNotEmpty);
      });
    });

    group('Status Transitions', () {
      test('transition from offline to connected', () {
        final statusStream = monitor.connectionStatusStream;

        expect(
          statusStream,
          emitsInOrder([
            FirebaseConnectionStatus.checking,
            FirebaseConnectionStatus.connected,
          ]),
        );
      });

      test('transition from connected to offline', () {
        final statusStream = monitor.connectionStatusStream;

        expect(
          statusStream,
          emitsInOrder([
            FirebaseConnectionStatus.connected,
            FirebaseConnectionStatus.offline,
          ]),
        );
      });
    });

    tearDown(() async {
      await monitor.dispose();
    });
  });

  group('Firebase Connection Status Enum', () {
    test('all enum values are distinct', () {
      expect(FirebaseConnectionStatus.checking, isNot(FirebaseConnectionStatus.connected));
      expect(FirebaseConnectionStatus.connected, isNot(FirebaseConnectionStatus.offline));
      expect(FirebaseConnectionStatus.offline, isNot(FirebaseConnectionStatus.error));
    });

    test('enum can be converted to string', () {
      expect(FirebaseConnectionStatus.checking.toString(), contains('checking'));
      expect(FirebaseConnectionStatus.connected.toString(), contains('connected'));
      expect(FirebaseConnectionStatus.offline.toString(), contains('offline'));
      expect(FirebaseConnectionStatus.error.toString(), contains('error'));
    });
  });
}
