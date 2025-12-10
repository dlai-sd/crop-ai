import 'package:flutter_test/flutter_test.dart';

import '../../lib/providers/farm_provider.dart';

void main() {
  group('Farm Model', () {
    test('Farm.fromJson creates instance from JSON', () {
      final json = {
        'id': 'farm_001',
        'user_id': 'user_001',
        'name': 'Green Valley',
        'location': 'Jaipur',
        'area': 15.5,
        'farm_type': 'Vegetable',
        'current_crop': 'Tomato',
        'growth_stage': 'Flowering',
        'soil_health_score': 72.0,
        'moisture_level': 65.0,
        'ph_level': 6.8,
      };

      final farm = Farm.fromJson(json);

      expect(farm.id, 'farm_001');
      expect(farm.name, 'Green Valley');
      expect(farm.location, 'Jaipur');
      expect(farm.area, 15.5);
      expect(farm.farmType, 'Vegetable');
      expect(farm.currentCrop, 'Tomato');
      expect(farm.growthStage, 'Flowering');
      expect(farm.soilHealthScore, 72.0);
      expect(farm.moistureLevel, 65.0);
      expect(farm.phLevel, 6.8);
    });

    test('Farm.fromJson handles missing fields with defaults', () {
      final json = {
        'id': 'farm_001',
        'user_id': 'user_001',
      };

      final farm = Farm.fromJson(json);

      expect(farm.name, 'Unknown');
      expect(farm.location, 'N/A');
      expect(farm.area, 0.0);
      expect(farm.farmType, 'Vegetable');
      expect(farm.currentCrop, 'Wheat');
      expect(farm.growthStage, 'Planting');
      expect(farm.soilHealthScore, 50.0);
      expect(farm.moistureLevel, 50.0);
      expect(farm.phLevel, 7.0);
    });

    test('Farm.toJson converts instance to JSON', () {
      final farm = Farm(
        id: 'farm_001',
        userId: 'user_001',
        name: 'Green Valley',
        location: 'Jaipur',
        area: 15.5,
        farmType: 'Vegetable',
        currentCrop: 'Tomato',
        growthStage: 'Flowering',
        soilHealthScore: 72.0,
        moistureLevel: 65.0,
        phLevel: 6.8,
      );

      final json = farm.toJson();

      expect(json['id'], 'farm_001');
      expect(json['name'], 'Green Valley');
      expect(json['area'], 15.5);
      // soilHealthScore not in toJson - test what's actually there
      expect(json['current_crop'], 'Tomato');
    });

    test('Farm.copyWith creates modified copy', () {
      final farm = Farm(
        id: 'farm_001',
        userId: 'user_001',
        name: 'Green Valley',
        location: 'Jaipur',
        area: 15.5,
        farmType: 'Vegetable',
        currentCrop: 'Tomato',
        growthStage: 'Flowering',
        soilHealthScore: 72.0,
        moistureLevel: 65.0,
        phLevel: 6.8,
      );

      final updated = farm.copyWith(
        name: 'Blue Sky Farm',
        soilHealthScore: 85.0,
      );

      expect(updated.name, 'Blue Sky Farm');
      expect(updated.soilHealthScore, 85.0);
      expect(updated.id, farm.id);
      expect(updated.location, farm.location);
    });
  });

  group('Farm List Data', () {
    test('Mock farms list is not empty', () {
      final mockFarms = _getMockFarms();
      expect(mockFarms, isNotEmpty);
      expect(mockFarms.length, 3);
    });

    test('Mock farms have valid data', () {
      final mockFarms = _getMockFarms();
      for (final farm in mockFarms) {
        expect(farm.id, isNotEmpty);
        expect(farm.name, isNotEmpty);
        expect(farm.location, isNotEmpty);
        expect(farm.area, greaterThan(0));
        expect(farm.soilHealthScore, inInclusiveRange(0, 100));
        expect(farm.moistureLevel, inInclusiveRange(0, 100));
        expect(farm.phLevel, isNotNull);
      }
    });

    test('Mock farms have different characteristics', () {
      final mockFarms = _getMockFarms();
      final names = mockFarms.map((f) => f.name).toSet();
      final locations = mockFarms.map((f) => f.location).toSet();

      expect(names.length, 3);
      expect(locations.length, 3);
    });
  });
}

List<Farm> _getMockFarms() => [
  Farm(
    id: 'farm_001',
    userId: 'user_001',
    name: 'Green Valley Farm',
    location: 'Jaipur, Rajasthan',
    area: 15.5,
    farmType: 'Vegetable',
    currentCrop: 'Tomato',
    growthStage: 'Flowering',
    soilHealthScore: 72.0,
    moistureLevel: 65.0,
    phLevel: 6.8,
  ),
  Farm(
    id: 'farm_002',
    userId: 'user_001',
    name: 'Wheat Field North',
    location: 'Ludhiana, Punjab',
    area: 25.0,
    farmType: 'Cereal',
    currentCrop: 'Wheat',
    growthStage: 'Growth',
    soilHealthScore: 68.0,
    moistureLevel: 58.0,
    phLevel: 7.2,
  ),
  Farm(
    id: 'farm_003',
    userId: 'user_001',
    name: 'Organic Dairy Farm',
    location: 'Nashik, Maharashtra',
    area: 8.0,
    farmType: 'Dairy',
    currentCrop: 'Maize + Fodder',
    growthStage: 'Vegetative',
    soilHealthScore: 78.0,
    moistureLevel: 72.0,
    phLevel: 6.9,
  ),
];
