import 'package:flutter/foundation.dart';

@immutable
class Weather {
  final String id;
  final String farmId;
  final double temperature; // Celsius
  final double feelsLike; // Celsius
  final double humidity; // Percentage (0-100)
  final double windSpeed; // km/h
  final double windDirection; // degrees (0-360)
  final double rainfall; // mm
  final double uvIndex;
  final String condition; // Clear, Cloudy, Rainy, Stormy, etc.
  final String description;
  final DateTime timestamp;
  final DateTime nextUpdate;

  const Weather({
    required this.id,
    required this.farmId,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.rainfall,
    required this.uvIndex,
    required this.condition,
    required this.description,
    required this.timestamp,
    required this.nextUpdate,
  });

  Weather copyWith({
    String? id,
    String? farmId,
    double? temperature,
    double? feelsLike,
    double? humidity,
    double? windSpeed,
    double? windDirection,
    double? rainfall,
    double? uvIndex,
    String? condition,
    String? description,
    DateTime? timestamp,
    DateTime? nextUpdate,
  }) {
    return Weather(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      rainfall: rainfall ?? this.rainfall,
      uvIndex: uvIndex ?? this.uvIndex,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      nextUpdate: nextUpdate ?? this.nextUpdate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmId': farmId,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'rainfall': rainfall,
      'uvIndex': uvIndex,
      'condition': condition,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'nextUpdate': nextUpdate.toIso8601String(),
    };
  }

  factory Weather.fromMap(Map<String, dynamic> map) {
    return Weather(
      id: map['id'] as String,
      farmId: map['farmId'] as String,
      temperature: (map['temperature'] as num).toDouble(),
      feelsLike: (map['feelsLike'] as num).toDouble(),
      humidity: (map['humidity'] as num).toDouble(),
      windSpeed: (map['windSpeed'] as num).toDouble(),
      windDirection: (map['windDirection'] as num).toDouble(),
      rainfall: (map['rainfall'] as num).toDouble(),
      uvIndex: (map['uvIndex'] as num).toDouble(),
      condition: map['condition'] as String,
      description: map['description'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      nextUpdate: DateTime.parse(map['nextUpdate'] as String),
    );
  }

  /// Get weather icon based on condition
  String getWeatherIcon() {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'cloudy':
        return '☁️';
      case 'rainy':
        return '🌧️';
      case 'stormy':
        return '⛈️';
      case 'partly cloudy':
        return '⛅';
      default:
        return '🌤️';
    }
  }

  /// Get weather icon emoji for wind
  String getWindIcon() => '💨';

  /// Get weather icon emoji for humidity
  String getHumidityIcon() => '💧';

  /// Get weather icon emoji for UV index
  String getUVIcon() => '☀️';

  /// Determine UV risk level
  String getUVRiskLevel() {
    if (uvIndex < 3) return 'Low';
    if (uvIndex < 6) return 'Moderate';
    if (uvIndex < 8) return 'High';
    if (uvIndex < 11) return 'Very High';
    return 'Extreme';
  }
}
