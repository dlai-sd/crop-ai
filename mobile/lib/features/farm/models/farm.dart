import 'package:flutter/foundation.dart';

@immutable
class Farm {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double areaHectares;
  final String cropType;
  final DateTime plantingDate;
  final DateTime? expectedHarvestDate;
  final String healthStatus;
  final double soilMoisture;
  final double temperature;
  final DateTime lastUpdated;

  const Farm({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.areaHectares,
    required this.cropType,
    required this.plantingDate,
    this.expectedHarvestDate,
    required this.healthStatus,
    required this.soilMoisture,
    required this.temperature,
    required this.lastUpdated,
  });

  Farm copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? areaHectares,
    String? cropType,
    DateTime? plantingDate,
    DateTime? expectedHarvestDate,
    String? healthStatus,
    double? soilMoisture,
    double? temperature,
    DateTime? lastUpdated,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      areaHectares: areaHectares ?? this.areaHectares,
      cropType: cropType ?? this.cropType,
      plantingDate: plantingDate ?? this.plantingDate,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
      healthStatus: healthStatus ?? this.healthStatus,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      temperature: temperature ?? this.temperature,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'areaHectares': areaHectares,
      'cropType': cropType,
      'plantingDate': plantingDate.toIso8601String(),
      'expectedHarvestDate': expectedHarvestDate?.toIso8601String(),
      'healthStatus': healthStatus,
      'soilMoisture': soilMoisture,
      'temperature': temperature,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      areaHectares: (map['areaHectares'] as num).toDouble(),
      cropType: map['cropType'] as String,
      plantingDate: DateTime.parse(map['plantingDate'] as String),
      expectedHarvestDate: map['expectedHarvestDate'] != null
          ? DateTime.parse(map['expectedHarvestDate'] as String)
          : null,
      healthStatus: map['healthStatus'] as String,
      soilMoisture: (map['soilMoisture'] as num).toDouble(),
      temperature: (map['temperature'] as num).toDouble(),
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }
}
