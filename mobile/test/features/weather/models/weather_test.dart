import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/weather/models/weather.dart';

void main() {
  group('Weather Model', () {
    final now = DateTime.now();

    test('Weather.fromMap creates weather from map', () {
      final map = {
        'id': 'w1',
        'farmId': 'farm1',
        'temperature': 28.5,
        'feelsLike': 30.2,
        'humidity': 75.0,
        'windSpeed': 12.5,
        'windDirection': 180.0,
        'rainfall': 2.3,
        'uvIndex': 6.5,
        'condition': 'Partly Cloudy',
        'description': 'Partly cloudy with mild winds',
        'timestamp': now.toIso8601String(),
        'nextUpdate': now.add(const Duration(hours: 1)).toIso8601String(),
      };

      final weather = Weather.fromMap(map);

      expect(weather.id, 'w1');
      expect(weather.farmId, 'farm1');
      expect(weather.temperature, 28.5);
      expect(weather.humidity, 75.0);
      expect(weather.condition, 'Partly Cloudy');
    });

    test('Weather.toMap converts weather to map', () {
      final weather = Weather(
        id: 'w1',
        farmId: 'farm1',
        temperature: 28.5,
        feelsLike: 30.2,
        humidity: 75,
        windSpeed: 12.5,
        windDirection: 180,
        rainfall: 2.3,
        uvIndex: 6.5,
        condition: 'Partly Cloudy',
        description: 'Partly cloudy with mild winds',
        timestamp: now,
        nextUpdate: now.add(const Duration(hours: 1)),
      );

      final map = weather.toMap();

      expect(map['id'], 'w1');
      expect(map['farmId'], 'farm1');
      expect(map['temperature'], 28.5);
      expect(map['humidity'], 75);
    });

    test('Weather.copyWith creates modified copy', () {
      final weather = Weather(
        id: 'w1',
        farmId: 'farm1',
        temperature: 28.5,
        feelsLike: 30.2,
        humidity: 75,
        windSpeed: 12.5,
        windDirection: 180,
        rainfall: 2.3,
        uvIndex: 6.5,
        condition: 'Partly Cloudy',
        description: 'Partly cloudy with mild winds',
        timestamp: now,
        nextUpdate: now.add(const Duration(hours: 1)),
      );

      final modified = weather.copyWith(temperature: 32.0, humidity: 60);

      expect(modified.temperature, 32.0);
      expect(modified.humidity, 60);
      expect(modified.id, 'w1'); // Unchanged
      expect(modified.condition, 'Partly Cloudy'); // Unchanged
    });

    test('getWeatherIcon returns correct emoji', () {
      final clear = Weather(
        id: 'w1',
        farmId: 'farm1',
        temperature: 28.5,
        feelsLike: 30.2,
        humidity: 75,
        windSpeed: 12.5,
        windDirection: 180,
        rainfall: 2.3,
        uvIndex: 6.5,
        condition: 'Clear',
        description: 'Clear skies',
        timestamp: now,
        nextUpdate: now.add(const Duration(hours: 1)),
      );

      expect(clear.getWeatherIcon(), '☀️');

      final rainy = clear.copyWith(condition: 'Rainy');
      expect(rainy.getWeatherIcon(), '🌧️');

      final stormy = clear.copyWith(condition: 'Stormy');
      expect(stormy.getWeatherIcon(), '⛈️');
    });

    test('getUVRiskLevel returns correct risk level', () {
      const now = Duration(hours: 0);

      final lowRisk = Weather(
        id: 'w1',
        farmId: 'farm1',
        temperature: 28.5,
        feelsLike: 30.2,
        humidity: 75,
        windSpeed: 12.5,
        windDirection: 180,
        rainfall: 2.3,
        uvIndex: 2.0,
        condition: 'Clear',
        description: 'Clear skies',
        timestamp: DateTime.now(),
        nextUpdate: DateTime.now(),
      );

      expect(lowRisk.getUVRiskLevel(), 'Low');

      final moderate = lowRisk.copyWith(uvIndex: 4.5);
      expect(moderate.getUVRiskLevel(), 'Moderate');

      final high = lowRisk.copyWith(uvIndex: 7.0);
      expect(high.getUVRiskLevel(), 'High');

      final veryHigh = lowRisk.copyWith(uvIndex: 9.5);
      expect(veryHigh.getUVRiskLevel(), 'Very High');

      final extreme = lowRisk.copyWith(uvIndex: 11.0);
      expect(extreme.getUVRiskLevel(), 'Extreme');
    });

    test('Weather emoji getters return correct emojis', () {
      final weather = Weather(
        id: 'w1',
        farmId: 'farm1',
        temperature: 28.5,
        feelsLike: 30.2,
        humidity: 75,
        windSpeed: 12.5,
        windDirection: 180,
        rainfall: 2.3,
        uvIndex: 6.5,
        condition: 'Partly Cloudy',
        description: 'Partly cloudy with mild winds',
        timestamp: now,
        nextUpdate: now.add(const Duration(hours: 1)),
      );

      expect(weather.getWindIcon(), '💨');
      expect(weather.getHumidityIcon(), '💧');
      expect(weather.getUVIcon(), '☀️');
    });
  });
}
