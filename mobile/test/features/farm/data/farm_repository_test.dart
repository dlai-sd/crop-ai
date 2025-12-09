import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/farm/data/farm_repository.dart';
import 'package:crop_ai/features/farm/models/farm.dart';

void main() {
  group('MockFarmRepository Tests', () {
    late MockFarmRepository repository;

    setUp(() {
      repository = MockFarmRepository();
    });

    test('getFarms returns non-empty list', () async {
      final farms = await repository.getFarms();
      expect(farms, isNotEmpty);
      expect(farms.length, 3);
    });

    test('getFarmById returns correct farm', () async {
      final farm = await repository.getFarmById('1');
      expect(farm, isNotNull);
      expect(farm!.name, 'Green Valley Farm');
      expect(farm.cropType, 'Wheat');
    });

    test('getFarmById returns null for non-existent farm', () async {
      final farm = await repository.getFarmById('999');
      expect(farm, isNull);
    });

    test('addFarm adds new farm to list', () async {
      final initialFarms = await repository.getFarms();
      final initialCount = initialFarms.length;

      final newFarm = Farm(
        id: '999',
        name: 'New Farm',
        latitude: 28.7041,
        longitude: 77.1025,
        areaHectares: 2.0,
        cropType: 'Rice',
        plantingDate: DateTime.now(),
        healthStatus: 'healthy',
        soilMoisture: 70.0,
        temperature: 25.0,
        lastUpdated: DateTime.now(),
      );

      await repository.addFarm(newFarm);
      final updatedFarms = await repository.getFarms();
      expect(updatedFarms.length, initialCount + 1);
    });
  });
}
