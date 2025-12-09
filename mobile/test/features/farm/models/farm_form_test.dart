import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/farm/models/farm_form.dart';

void main() {
  group('FormValidation', () {
    test('validateFarmName accepts valid names', () {
      expect(FormValidation.validateFarmName('Green Valley Farm'), isNull);
      expect(FormValidation.validateFarmName('Farm 123'), isNull);
    });

    test('validateFarmName rejects empty names', () {
      expect(FormValidation.validateFarmName(''), isNotNull);
      expect(FormValidation.validateFarmName(null), isNotNull);
    });

    test('validateFarmName rejects names less than 2 characters', () {
      expect(FormValidation.validateFarmName('A'), isNotNull);
    });

    test('validateFarmName rejects names exceeding 50 characters', () {
      final longName = 'a' * 51;
      expect(FormValidation.validateFarmName(longName), isNotNull);
    });

    test('validateArea accepts valid areas', () {
      expect(FormValidation.validateArea('10'), isNull);
      expect(FormValidation.validateArea('10.5'), isNull);
      expect(FormValidation.validateArea('0.1'), isNull);
    });

    test('validateArea rejects invalid areas', () {
      expect(FormValidation.validateArea(''), isNotNull);
      expect(FormValidation.validateArea(null), isNotNull);
      expect(FormValidation.validateArea('abc'), isNotNull);
      expect(FormValidation.validateArea('0'), isNotNull);
      expect(FormValidation.validateArea('-10'), isNotNull);
    });

    test('validateArea rejects areas exceeding 10000 hectares', () {
      expect(FormValidation.validateArea('10001'), isNotNull);
    });

    test('validateCoordinate validates latitude', () {
      expect(FormValidation.validateCoordinate('0', 'Latitude'), isNull);
      expect(FormValidation.validateCoordinate('90', 'Latitude'), isNull);
      expect(FormValidation.validateCoordinate('-90', 'Latitude'), isNull);
      expect(FormValidation.validateCoordinate('91', 'Latitude'), isNotNull);
      expect(FormValidation.validateCoordinate('-91', 'Latitude'), isNotNull);
    });

    test('validateCoordinate validates longitude', () {
      expect(FormValidation.validateCoordinate('0', 'Longitude'), isNull);
      expect(FormValidation.validateCoordinate('180', 'Longitude'), isNull);
      expect(FormValidation.validateCoordinate('-180', 'Longitude'), isNull);
      expect(FormValidation.validateCoordinate('181', 'Longitude'), isNotNull);
      expect(FormValidation.validateCoordinate('-181', 'Longitude'), isNotNull);
    });

    test('validateMoisture accepts valid moisture values', () {
      expect(FormValidation.validateMoisture('0'), isNull);
      expect(FormValidation.validateMoisture('50'), isNull);
      expect(FormValidation.validateMoisture('100'), isNull);
      expect(FormValidation.validateMoisture('75.5'), isNull);
    });

    test('validateMoisture rejects invalid values', () {
      expect(FormValidation.validateMoisture(''), isNotNull);
      expect(FormValidation.validateMoisture(null), isNotNull);
      expect(FormValidation.validateMoisture('abc'), isNotNull);
      expect(FormValidation.validateMoisture('-1'), isNotNull);
      expect(FormValidation.validateMoisture('101'), isNotNull);
    });

    test('validateTemperature accepts valid temperatures', () {
      expect(FormValidation.validateTemperature('-50'), isNull);
      expect(FormValidation.validateTemperature('0'), isNull);
      expect(FormValidation.validateTemperature('25'), isNull);
      expect(FormValidation.validateTemperature('60'), isNull);
    });

    test('validateTemperature rejects invalid values', () {
      expect(FormValidation.validateTemperature(''), isNotNull);
      expect(FormValidation.validateTemperature(null), isNotNull);
      expect(FormValidation.validateTemperature('abc'), isNotNull);
      expect(FormValidation.validateTemperature('-51'), isNotNull);
      expect(FormValidation.validateTemperature('61'), isNotNull);
    });
  });

  group('FarmFormModel', () {
    test('empty creates a new farm form with defaults', () {
      final form = FarmFormModel.empty();

      expect(form.id, isNull);
      expect(form.name, isEmpty);
      expect(form.areaHectares, 0.0);
      expect(form.cropType, 'Rice');
      expect(form.healthStatus, 'healthy');
    });

    test('fromFarm creates form from existing farm', () {
      final farm = _createTestFarm();
      final form = FarmFormModel.fromFarm(farm);

      expect(form.id, farm.id);
      expect(form.name, farm.name);
      expect(form.areaHectares, farm.areaHectares);
      expect(form.cropType, farm.cropType);
    });

    test('toFarm converts form to farm model', () {
      final form = FarmFormModel(
        id: 'test-id',
        name: 'Test Farm',
        latitude: 10.5,
        longitude: 20.5,
        areaHectares: 5.0,
        cropType: 'Wheat',
        plantingDate: DateTime(2024, 1, 1),
        healthStatus: 'healthy',
        soilMoisture: 50.0,
        temperature: 25.0,
      );

      final farm = form.toFarm();

      expect(farm.id, 'test-id');
      expect(farm.name, 'Test Farm');
      expect(farm.cropType, 'Wheat');
    });

    test('toFarm generates new ID if not provided', () {
      final form = FarmFormModel.empty().copyWith(
        name: 'New Farm',
        areaHectares: 10.0,
      );

      final farm = form.toFarm();

      expect(farm.id, isNotEmpty);
      expect(farm.id.length, 36); // UUID length
    });

    test('copyWith creates new instance with updated values', () {
      final form1 = FarmFormModel.empty();
      final form2 = form1.copyWith(name: 'Updated Farm');

      expect(form1.name, isEmpty);
      expect(form2.name, 'Updated Farm');
    });
  });

  group('CropType', () {
    test('options contains expected crops', () {
      expect(CropType.options, contains('Rice'));
      expect(CropType.options, contains('Wheat'));
      expect(CropType.options, contains('Tomato'));
    });

    test('emoji maps crops to emojis', () {
      expect(CropType.emoji['Rice'], '🌾');
      expect(CropType.emoji['Tomato'], '🍅');
      expect(CropType.emoji['Corn'], '🌽');
    });
  });

  group('HealthStatus', () {
    test('options contains expected statuses', () {
      expect(HealthStatus.options, ['healthy', 'warning', 'critical']);
    });

    test('labels maps statuses to display labels', () {
      expect(HealthStatus.labels['healthy'], 'Healthy');
      expect(HealthStatus.labels['warning'], 'Warning');
      expect(HealthStatus.labels['critical'], 'Critical');
    });

    test('colors maps statuses to colors', () {
      expect(HealthStatus.colors['healthy'], const Color(0xFF4CAF50));
      expect(HealthStatus.colors['warning'], const Color(0xFFFFC107));
      expect(HealthStatus.colors['critical'], const Color(0xFFF44336));
    });
  });
}

Farm _createTestFarm() {
  return Farm(
    id: 'test-farm-1',
    name: 'Test Farm',
    latitude: 10.5,
    longitude: 20.5,
    areaHectares: 5.0,
    cropType: 'Rice',
    plantingDate: DateTime(2024, 1, 1),
    healthStatus: 'healthy',
    soilMoisture: 50.0,
    temperature: 25.0,
    lastUpdated: DateTime.now(),
  );
}

// Import Farm model
import 'package:crop_ai/features/farm/models/farm.dart';
import 'dart:ui';
