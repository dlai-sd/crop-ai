import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/farm/models/farm.dart';

void main() {
  group('Farm Model Tests', () {
    test('Farm.fromMap creates Farm correctly', () {
      final map = {
        'id': '1',
        'name': 'Test Farm',
        'latitude': 28.7041,
        'longitude': 77.1025,
        'areaHectares': 5.5,
        'cropType': 'Wheat',
        'plantingDate': '2025-10-15T00:00:00.000Z',
        'expectedHarvestDate': '2026-03-15T00:00:00.000Z',
        'healthStatus': 'healthy',
        'soilMoisture': 75.5,
        'temperature': 22.3,
        'lastUpdated': '2025-12-09T10:30:00.000Z',
      };

      final farm = Farm.fromMap(map);

      expect(farm.id, '1');
      expect(farm.name, 'Test Farm');
      expect(farm.cropType, 'Wheat');
      expect(farm.healthStatus, 'healthy');
    });

    test('Farm.copyWith creates new Farm with updated fields', () {
      final farm = Farm(
        id: '1',
        name: 'Original',
        latitude: 28.7041,
        longitude: 77.1025,
        areaHectares: 5.5,
        cropType: 'Wheat',
        plantingDate: DateTime(2025, 10, 15),
        healthStatus: 'healthy',
        soilMoisture: 75.5,
        temperature: 22.3,
        lastUpdated: DateTime(2025, 12, 9),
      );

      final updated = farm.copyWith(name: 'Updated', soilMoisture: 60.0);

      expect(updated.name, 'Updated');
      expect(updated.soilMoisture, 60.0);
      expect(updated.id, '1');
    });
  });
}
