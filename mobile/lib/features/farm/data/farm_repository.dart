import 'package:crop_ai/features/farm/models/farm.dart';

abstract class FarmRepository {
  Future<List<Farm>> getFarms();
  Future<Farm?> getFarmById(String farmId);
  Future<void> addFarm(Farm farm);
  Future<void> updateFarm(Farm farm);
  Future<void> deleteFarm(String farmId);
}

class MockFarmRepository implements FarmRepository {
  static final List<Farm> _mockFarms = [
    Farm(
      id: '1',
      name: 'Green Valley Farm',
      latitude: 28.7041,
      longitude: 77.1025,
      areaHectares: 5.5,
      cropType: 'Wheat',
      plantingDate: DateTime(2025, 10, 15),
      expectedHarvestDate: DateTime(2026, 3, 15),
      healthStatus: 'healthy',
      soilMoisture: 75.5,
      temperature: 22.3,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Farm(
      id: '2',
      name: 'Sunrise Fields',
      latitude: 28.7142,
      longitude: 77.1050,
      areaHectares: 8.2,
      cropType: 'Rice',
      plantingDate: DateTime(2025, 9, 20),
      expectedHarvestDate: DateTime(2026, 2, 20),
      healthStatus: 'warning',
      soilMoisture: 45.2,
      temperature: 24.1,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Farm(
      id: '3',
      name: 'Harvest Moon Acres',
      latitude: 28.6920,
      longitude: 77.0930,
      areaHectares: 3.8,
      cropType: 'Maize',
      plantingDate: DateTime(2025, 11, 01),
      expectedHarvestDate: DateTime(2026, 4, 01),
      healthStatus: 'healthy',
      soilMoisture: 68.9,
      temperature: 21.5,
      lastUpdated: DateTime.now(),
    ),
  ];

  @override
  Future<List<Farm>> getFarms() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockFarms;
  }

  @override
  Future<Farm?> getFarmById(String farmId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockFarms.firstWhere((farm) => farm.id == farmId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addFarm(Farm farm) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockFarms.add(farm);
  }

  @override
  Future<void> updateFarm(Farm farm) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockFarms.indexWhere((f) => f.id == farm.id);
    if (index != -1) {
      _mockFarms[index] = farm;
    }
  }

  @override
  Future<void> deleteFarm(String farmId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockFarms.removeWhere((farm) => farm.id == farmId);
  }
}
