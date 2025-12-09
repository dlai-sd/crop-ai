import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/farm/models/farm.dart';
import 'package:crop_ai/features/farm/data/farm_repository.dart';
import 'package:crop_ai/features/weather/data/weather_repository.dart';
import 'package:crop_ai/features/offline_sync/data/sync_service.dart';
import 'package:crop_ai/features/offline_sync/data/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('Epic 1 Integration Tests', () {
    late MockFarmRepository farmRepository;
    late MockWeatherRepository weatherRepository;
    late OfflineSyncService syncService;
    late AppDatabase database;

    setUpAll(() {
      farmRepository = MockFarmRepository();
      weatherRepository = MockWeatherRepository();
      database = AppDatabase(drift.DriftQueryExecutor.inMemory());
      syncService = OfflineSyncService(database);
    });

    group('Farm Lifecycle', () {
      test('Create → Read → Update → Delete farm workflow', () async {
        // CREATE
        final testFarm = Farm(
          id: 'integration-test-1',
          name: 'Integration Test Farm',
          latitude: 28.5355,
          longitude: 77.3910,
          areaHectares: 5.5,
          cropType: 'Wheat',
          plantingDate: DateTime(2024, 10, 1),
          expectedHarvestDate: DateTime(2025, 2, 1),
          healthStatus: 'healthy',
          soilMoisture: 65.0,
          temperature: 22.5,
          lastUpdated: DateTime.now(),
        );

        await farmRepository.addFarm(testFarm);
        await syncService.queueFarmOperation('integration-test-1', 'create', testFarm.toMap());

        // READ
        final farm = await farmRepository.getFarmById('integration-test-1');
        expect(farm, isNotNull);
        expect(farm!.name, 'Integration Test Farm');
        expect(farm.areaHectares, 5.5);

        final allFarms = await farmRepository.getFarms();
        expect(allFarms, isNotEmpty);

        // UPDATE
        final updatedFarm = farm.copyWith(
          healthStatus: 'warning',
          soilMoisture: 45.0,
        );
        await farmRepository.updateFarm(updatedFarm);
        await syncService.queueFarmOperation('integration-test-1', 'update', updatedFarm.toMap());

        final fetchedUpdated = await farmRepository.getFarmById('integration-test-1');
        expect(fetchedUpdated!.healthStatus, 'warning');
        expect(fetchedUpdated.soilMoisture, 45.0);

        // DELETE
        await farmRepository.deleteFarm('integration-test-1');
        await syncService.queueFarmOperation('integration-test-1', 'delete', {'id': 'integration-test-1'});

        final pendingOps = await syncService.getPendingOperations();
        expect(pendingOps.any((op) => op.operation == 'delete'), true);
      });

      test('Multiple farms can coexist', () async {
        final farm1 = Farm(
          id: 'farm-1',
          name: 'Farm Alpha',
          latitude: 10.0,
          longitude: 20.0,
          areaHectares: 10.0,
          cropType: 'Rice',
          plantingDate: DateTime.now(),
          healthStatus: 'healthy',
          soilMoisture: 70.0,
          temperature: 28.0,
          lastUpdated: DateTime.now(),
        );

        final farm2 = Farm(
          id: 'farm-2',
          name: 'Farm Beta',
          latitude: 15.0,
          longitude: 25.0,
          areaHectares: 8.0,
          cropType: 'Wheat',
          plantingDate: DateTime.now(),
          healthStatus: 'warning',
          soilMoisture: 50.0,
          temperature: 25.0,
          lastUpdated: DateTime.now(),
        );

        await farmRepository.addFarm(farm1);
        await farmRepository.addFarm(farm2);

        final farms = await farmRepository.getFarms();
        expect(farms.where((f) => f.id == 'farm-1'), isNotEmpty);
        expect(farms.where((f) => f.id == 'farm-2'), isNotEmpty);
        expect(farms.length, greaterThanOrEqualTo(2));
      });
    });

    group('Weather Integration', () {
      test('Get weather for existing farm', () async {
        final weather = await weatherRepository.getWeatherByFarmId('farm1');

        expect(weather.farmId, 'farm1');
        expect(weather.temperature, isNotNull);
        expect(weather.humidity, isNotNull);
        expect(weather.windSpeed, isNotNull);
        expect(weather.uvIndex, isNotNull);
      });

      test('Get forecast for farm', () async {
        final forecast = await weatherRepository.getForecastByFarmId('farm1');

        expect(forecast, isNotEmpty);
        expect(forecast.length, 40); // 5 days * 8 intervals

        // Verify timestamps are sequential
        for (int i = 1; i < forecast.length; i++) {
          expect(
            forecast[i].timestamp.isAfter(forecast[i - 1].timestamp),
            true,
            reason: 'Forecast timestamps should be sequential',
          );
        }
      });

      test('Weather data matches farm location', () async {
        final farm = await farmRepository.getFarmById('farm1');
        expect(farm, isNotNull);

        final weather = await weatherRepository.getWeatherByFarmId(farm!.id);
        expect(weather.farmId, farm.id);
      });

      test('Weather UV index classification works', () async {
        final weather = await weatherRepository.getWeatherByFarmId('farm1');

        final riskLevel = weather.getUVRiskLevel();
        expect(['Low', 'Moderate', 'High', 'Very High', 'Extreme'], contains(riskLevel));
      });
    });

    group('Offline Sync Workflow', () {
      test('Queue multiple operations and track sync state', () async {
        final farm = Farm(
          id: 'sync-test-1',
          name: 'Sync Test Farm',
          latitude: 20.0,
          longitude: 30.0,
          areaHectares: 3.0,
          cropType: 'Cotton',
          plantingDate: DateTime.now(),
          healthStatus: 'healthy',
          soilMoisture: 60.0,
          temperature: 24.0,
          lastUpdated: DateTime.now(),
        );

        // Queue create
        await syncService.queueFarmOperation('sync-test-1', 'create', farm.toMap());

        var pending = await syncService.getPendingOperations();
        expect(pending.length, greaterThan(0));

        // Queue update
        final updatedFarm = farm.copyWith(healthStatus: 'warning');
        await syncService.queueFarmOperation('sync-test-1', 'update', updatedFarm.toMap());

        pending = await syncService.getPendingOperations();
        final createOp = pending.firstWhere((op) => op.operation == 'create');
        expect(createOp.farmId, 'sync-test-1');

        // Mark first operation as synced
        await syncService.markOperationSynced(createOp.id);

        pending = await syncService.getPendingOperations();
        expect(pending.where((op) => op.id == createOp.id), isEmpty);
      });

      test('Retry mechanism tracks failed operations', () async {
        await syncService.queueFarmOperation('retry-test', 'create', {'name': 'Test'});

        var pending = await syncService.getPendingOperations();
        final op = pending.first;

        expect(op.canRetry(), true);

        // Simulate retries
        for (int i = 0; i < 3; i++) {
          await syncService.retryOperation(op.id, error: 'Network timeout');
        }

        // After 3 retries, shouldn't be able to retry anymore
        pending = await syncService.getPendingOperations();
        final retriedOp = pending.firstWhere((o) => o.id == op.id);
        expect(retriedOp.retryCount, 3);
        expect(retriedOp.canRetry(), false);
      });

      test('Sync timestamp tracking', () async {
        expect(await syncService.getLastSyncTime(), isNull);

        final beforeSync = DateTime.now();
        await syncService.setLastSyncTime(beforeSync);

        final lastSync = await syncService.getLastSyncTime();
        expect(lastSync, isNotNull);
        expect(lastSync!.isAfter(beforeSync.subtract(const Duration(seconds: 1))), true);
      });

      test('Cleared operations are removed from queue', () async {
        await syncService.queueFarmOperation('clear-test-1', 'create', {});
        await syncService.queueFarmOperation('clear-test-2', 'create', {});

        var pending = await syncService.getPendingOperations();
        final initialCount = pending.length;

        // Mark one as synced
        await syncService.markOperationSynced(pending.first.id);
        await syncService.clearCompletedOperations();

        pending = await syncService.getPendingOperations();
        expect(pending.length, lessThan(initialCount));
      });
    });

    group('Conflict Resolution', () {
      test('Last-write-wins strategy selects newer data', () async {
        final now = DateTime.now();
        final older = now.subtract(const Duration(hours: 1));

        final local = {
          'name': 'Old Name',
          'lastUpdated': older.toIso8601String(),
        };

        final remote = {
          'name': 'New Name',
          'lastUpdated': now.toIso8601String(),
        };

        final resolved = syncService.resolveConflictLastWriteWins(local, remote);
        expect(resolved['name'], 'New Name');
      });

      test('Manual conflict resolution uses user choice', () async {
        final local = {'name': 'Local'};
        final remote = {'name': 'Remote'};
        final choice = {'name': 'Merged'};

        final resolved = syncService.resolveConflictManual(local, remote, choice);
        expect(resolved['name'], 'Merged');
      });

      test('Conflict resolution falls back to local when no choice', () async {
        final local = {'name': 'Local'};
        final remote = {'name': 'Remote'};

        final resolved = syncService.resolveConflictManual(local, remote, null);
        expect(resolved['name'], 'Local');
      });
    });

    group('Data Consistency', () {
      test('Farm serialization and deserialization maintains data', () async {
        final original = Farm(
          id: 'consistency-test',
          name: 'Consistency Farm',
          latitude: 25.123456,
          longitude: 75.654321,
          areaHectares: 7.89,
          cropType: 'Sugarcane',
          plantingDate: DateTime(2024, 5, 15),
          expectedHarvestDate: DateTime(2025, 3, 15),
          healthStatus: 'critical',
          soilMoisture: 35.5,
          temperature: 30.2,
          lastUpdated: DateTime(2024, 12, 1),
        );

        // Serialize
        final map = original.toMap();

        // Deserialize
        final restored = Farm.fromMap(map);

        // Verify all fields match
        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.latitude, original.latitude);
        expect(restored.longitude, original.longitude);
        expect(restored.areaHectares, original.areaHectares);
        expect(restored.cropType, original.cropType);
        expect(restored.plantingDate, original.plantingDate);
        expect(restored.expectedHarvestDate, original.expectedHarvestDate);
        expect(restored.healthStatus, original.healthStatus);
        expect(restored.soilMoisture, original.soilMoisture);
        expect(restored.temperature, original.temperature);
      });

      test('Weather data maintains precision', () async {
        final weather = await weatherRepository.getWeatherByFarmId('farm2');

        // Verify decimal precision is maintained
        expect(weather.temperature, greaterThan(0));
        expect(weather.humidity, greaterThanOrEqualTo(0));
        expect(weather.humidity, lessThanOrEqualTo(100));
        expect(weather.uvIndex, greaterThanOrEqualTo(0));
      });
    });

    group('Error Handling', () {
      test('Non-existent farm returns null', () async {
        final farm = await farmRepository.getFarmById('non-existent-farm-id');
        expect(farm, isNull);
      });

      test('Invalid farm ID throws exception', () async {
        expect(
          () => weatherRepository.getWeatherByFarmId('invalid-farm'),
          throwsA(isA<Exception>()),
        );
      });

      test('Historical weather requires valid date range', () async {
        final start = DateTime(2024, 1, 10);
        final end = DateTime(2024, 1, 5); // End before start

        final historical = await weatherRepository.getHistoricalWeatherByFarmId(
          'farm1',
          startDate: start,
          endDate: end,
        );

        expect(historical, isEmpty);
      });
    });

    group('Performance', () {
      test('Multiple farms query completes quickly', () async {
        final stopwatch = Stopwatch()..start();

        await farmRepository.getFarms();

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('Weather forecast generation completes in reasonable time', () async {
        final stopwatch = Stopwatch()..start();

        await weatherRepository.getForecastByFarmId('farm1');

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      test('Sync queue operations are efficient', () async {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 50; i++) {
          await syncService.queueFarmOperation('farm-$i', 'create', {'index': i});
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        final operations = await syncService.getPendingOperations();
        expect(operations.length, greaterThanOrEqualTo(50));
      });
    });
  });
}
