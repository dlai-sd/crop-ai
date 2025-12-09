import 'package:crop_ai_mobile/features/weather/models/weather.dart';

/// Abstract weather repository interface
abstract class WeatherRepository {
  /// Fetch weather for a specific farm
  Future<Weather> getWeatherByFarmId(String farmId);

  /// Fetch weather forecast (5 day, 3-hour intervals)
  Future<List<Weather>> getForecastByFarmId(String farmId);

  /// Update weather for a farm
  Future<void> updateWeather(String farmId, Weather weather);

  /// Get historical weather data
  Future<List<Weather>> getHistoricalWeatherByFarmId(
    String farmId, {
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// Mock weather repository with sample data
class MockWeatherRepository implements WeatherRepository {
  // Mock weather data for different conditions
  static final Map<String, Weather> _mockWeatherData = {
    'farm1': Weather(
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
      timestamp: DateTime.now(),
      nextUpdate: DateTime.now().add(const Duration(hours: 1)),
    ),
    'farm2': Weather(
      id: 'w2',
      farmId: 'farm2',
      temperature: 32.1,
      feelsLike: 34.8,
      humidity: 55,
      windSpeed: 8.2,
      windDirection: 270,
      rainfall: 0.0,
      uvIndex: 8.2,
      condition: 'Clear',
      description: 'Clear skies with strong sun',
      timestamp: DateTime.now(),
      nextUpdate: DateTime.now().add(const Duration(hours: 1)),
    ),
    'farm3': Weather(
      id: 'w3',
      farmId: 'farm3',
      temperature: 24.3,
      feelsLike: 22.1,
      humidity: 85,
      windSpeed: 18.5,
      windDirection: 90,
      rainfall: 12.5,
      uvIndex: 3.2,
      condition: 'Rainy',
      description: 'Light rain with moderate winds',
      timestamp: DateTime.now(),
      nextUpdate: DateTime.now().add(const Duration(hours: 1)),
    ),
  };

  @override
  Future<Weather> getWeatherByFarmId(String farmId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final weather = _mockWeatherData[farmId];
    if (weather != null) {
      return weather;
    }

    throw Exception('Weather data not found for farm: $farmId');
  }

  @override
  Future<List<Weather>> getForecastByFarmId(String farmId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final baseWeather = _mockWeatherData[farmId];
    if (baseWeather != null) {
      // Generate 5-day forecast with 3-hour intervals (simplified: 8 entries per day)
      final forecast = <Weather>[];
      var currentTime = DateTime.now();

      for (int i = 0; i < 40; i++) {
        // 5 days * 8 intervals
        final variation = (i % 3) - 1; // -1, 0, 1 for variation
        forecast.add(
          baseWeather.copyWith(
            id: 'w${farmId}_f$i',
            temperature: baseWeather.temperature + variation,
            humidity: (baseWeather.humidity + (variation * 5)).clamp(0, 100),
            timestamp: currentTime,
            nextUpdate: currentTime.add(const Duration(hours: 3)),
          ),
        );
        currentTime = currentTime.add(const Duration(hours: 3));
      }

      return forecast;
    }

    throw Exception('Weather forecast not found for farm: $farmId');
  }

  @override
  Future<void> updateWeather(String farmId, Weather weather) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    _mockWeatherData[farmId] = weather;
  }

  @override
  Future<List<Weather>> getHistoricalWeatherByFarmId(
    String farmId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final baseWeather = _mockWeatherData[farmId];
    if (baseWeather != null) {
      final historical = <Weather>[];
      var currentDate = startDate;

      // Generate daily historical data
      while (currentDate.isBefore(endDate)) {
        final variation = (currentDate.day % 5) - 2; // -2 to 2 variation
        historical.add(
          baseWeather.copyWith(
            id: 'w${farmId}_h${currentDate.millisecondsSinceEpoch}',
            temperature: baseWeather.temperature + variation,
            humidity: (baseWeather.humidity + (variation * 3)).clamp(0, 100),
            timestamp: currentDate,
            nextUpdate: currentDate.add(const Duration(hours: 24)),
          ),
        );
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return historical;
    }

    throw Exception('Historical weather not found for farm: $farmId');
  }
}
