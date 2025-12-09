import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:crop_ai/features/farm/models/farm.dart';
import 'package:crop_ai/core/localization/app_localizations.dart';

/// Form model for farm creation and editing
class FarmFormModel {
  final String? id;
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
  final String? photoPath;

  FarmFormModel({
    this.id,
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
    this.photoPath,
  });

  /// Create from existing Farm
  factory FarmFormModel.fromFarm(Farm farm) {
    return FarmFormModel(
      id: farm.id,
      name: farm.name,
      latitude: farm.latitude,
      longitude: farm.longitude,
      areaHectares: farm.areaHectares,
      cropType: farm.cropType,
      plantingDate: farm.plantingDate,
      expectedHarvestDate: farm.expectedHarvestDate,
      healthStatus: farm.healthStatus,
      soilMoisture: farm.soilMoisture,
      temperature: farm.temperature,
    );
  }

  /// Create empty form for new farm
  factory FarmFormModel.empty() {
    return FarmFormModel(
      name: '',
      latitude: 0.0,
      longitude: 0.0,
      areaHectares: 0.0,
      cropType: 'Rice',
      plantingDate: DateTime.now(),
      healthStatus: 'healthy',
      soilMoisture: 50.0,
      temperature: 25.0,
    );
  }

  /// Convert to Farm model
  Farm toFarm() {
    return Farm(
      id: id ?? const Uuid().v4(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      areaHectares: areaHectares,
      cropType: cropType,
      plantingDate: plantingDate,
      expectedHarvestDate: expectedHarvestDate,
      healthStatus: healthStatus,
      soilMoisture: soilMoisture,
      temperature: temperature,
      lastUpdated: DateTime.now(),
    );
  }

  /// Copy with new values
  FarmFormModel copyWith({
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
    String? photoPath,
  }) {
    return FarmFormModel(
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
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

/// Validation utility
class FormValidation {
  static String? validateFarmName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Farm name is required';
    }
    if (value.length < 2) {
      return 'Farm name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Farm name must not exceed 50 characters';
    }
    return null;
  }

  static String? validateArea(String? value) {
    if (value == null || value.isEmpty) {
      return 'Area is required';
    }
    final area = double.tryParse(value);
    if (area == null) {
      return 'Please enter a valid number';
    }
    if (area <= 0) {
      return 'Area must be greater than 0';
    }
    if (area > 10000) {
      return 'Area must not exceed 10,000 hectares';
    }
    return null;
  }

  static String? validateCoordinate(String? value, String coordinateName) {
    if (value == null || value.isEmpty) {
      return '$coordinateName is required';
    }
    final coord = double.tryParse(value);
    if (coord == null) {
      return 'Please enter a valid number';
    }
    if (coordinateName == 'Latitude' && (coord < -90 || coord > 90)) {
      return 'Latitude must be between -90 and 90';
    }
    if (coordinateName == 'Longitude' && (coord < -180 || coord > 180)) {
      return 'Longitude must be between -180 and 180';
    }
    return null;
  }

  static String? validateMoisture(String? value) {
    if (value == null || value.isEmpty) {
      return 'Soil moisture is required';
    }
    final moisture = double.tryParse(value);
    if (moisture == null) {
      return 'Please enter a valid number';
    }
    if (moisture < 0 || moisture > 100) {
      return 'Soil moisture must be between 0 and 100%';
    }
    return null;
  }

  static String? validateTemperature(String? value) {
    if (value == null || value.isEmpty) {
      return 'Temperature is required';
    }
    final temp = double.tryParse(value);
    if (temp == null) {
      return 'Please enter a valid number';
    }
    if (temp < -50 || temp > 60) {
      return 'Temperature must be between -50 and 60°C';
    }
    return null;
  }
}

/// Crop type options
class CropType {
  static const List<String> options = [
    'Rice',
    'Wheat',
    'Corn',
    'Cotton',
    'Sugarcane',
    'Potato',
    'Tomato',
    'Onion',
    'Cabbage',
    'Carrot',
    'Beans',
    'Peas',
    'Sunflower',
    'Groundnut',
  ];

  static const Map<String, String> emoji = {
    'Rice': '🌾',
    'Wheat': '🌾',
    'Corn': '🌽',
    'Cotton': '🧵',
    'Sugarcane': '🍃',
    'Potato': '🥔',
    'Tomato': '🍅',
    'Onion': '🧅',
    'Cabbage': '🥬',
    'Carrot': '🥕',
    'Beans': '🫘',
    'Peas': '🫛',
    'Sunflower': '🌻',
    'Groundnut': '🥜',
  };
}

/// Health status options
class HealthStatus {
  static const List<String> options = ['healthy', 'warning', 'critical'];

  static const Map<String, Color> colors = {
    'healthy': Color(0xFF4CAF50),
    'warning': Color(0xFFFFC107),
    'critical': Color(0xFFF44336),
  };

  static const Map<String, String> labels = {
    'healthy': 'Healthy',
    'warning': 'Warning',
    'critical': 'Critical',
  };
}
