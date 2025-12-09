import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/weather/data/weather_repository.dart';

void main() {
  group('MockWeatherRepository', () {
    late MockWeatherRepository repository;

    setUp(() {
      repository = MockWeatherRepository();
    });

    test('getWeatherByFarmId returns weather for valid farm', () async {
      final weather = await repository.getWeatherByFarmId('farm1');

      expect(weather, isNotNull);
      expect(weather.farmId, 'farm1');
      expect(weather.temperature, isNotNull);
      expect(weather.humidity, isNotNull);
    });

    test('getWeatherByFarmId returns different data for different farms', () async {
      final weather1 = await repository.getWeatherByFarmId('farm1');
      final weather2 = await repository.getWeatherByFarmId('farm2');

      expect(weather1.farmId, 'farm1');
      expect(weather2.farmId, 'farm2');
      expect(weather1.temperature, isNot(weather2.temperature));
    });

    test('getWeatherByFarmId throws for invalid farm', () async {
      expect(
        () => repository.getWeatherByFarmId('nonexistent'),
        throwsA(isA<Exception>()),
      );
    });

    test('getForecastByFarmId returns list of weather', () async {
      final forecast = await repository.getForecastByFarmId('farm1');

      expect(forecast, isNotNull);
      expect(forecast, isNotEmpty);
      expect(forecast.length, 40); // 5 days * 8 intervals
    });

    test('getForecastByFarmId returns weather with increasing timestamps', () async {
      final forecast = await repository.getForecastByFarmId('farm1');

      for (int i = 1; i < forecast.length; i++) {
        expect(
          forecast[i].timestamp.isAfter(forecast[i - 1].timestamp),
          true,
        );
      }
    });

    test('updateWeather updates mock data', () async {
      final original = await repository.getWeatherByFarmId('farm1');
      expect(original.temperature, 28.5);

      final updated = original.copyWith(temperature: 35.0);
      await repository.updateWeather('farm1', updated);

      final fetched = await repository.getWeatherByFarmId('farm1');
      expect(fetched.temperature, 35.0);
    });

    test('getHistoricalWeatherByFarmId returns daily data', () async {
      final startDate = DateTime.now().subtract(const Duration(days: 7));
      final endDate = DateTime.now();

      final historical = await repository.getHistoricalWeatherByFarmId(
        'farm1',
        startDate: startDate,
        endDate: endDate,
      );

      expect(historical, isNotEmpty);
      expect(
        historical.length,
        endDate.difference(startDate).inDays,
      );
    });

    test('getHistoricalWeatherByFarmId returns weather with correct dates', () async {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 5);

      final historical = await repository.getHistoricalWeatherByFarmId(
        'farm1',
        startDate: startDate,
        endDate: endDate,
      );

      // Should be 4 days of data (Jan 1-4)
      expect(historical.length, 4);

      // Verify dates are sequential
      for (int i = 1; i < historical.length; i++) {
        final daysDiff =
            historical[i].timestamp.difference(historical[i - 1].timestamp).inDays;
        expect(daysDiff, 1);
      }
    });

    test('Weather data contains all required fields', () async {
      final weather = await repository.getWeatherByFarmId('farm1');

      expect(weather.id, isNotEmpty);
      expect(weather.farmId, isNotEmpty);
      expect(weather.temperature, isNotNull);
      expect(weather.feelsLike, isNotNull);
      expect(weather.humidity, isNotNull);
      expect(weather.windSpeed, isNotNull);
      expect(weather.windDirection, isNotNull);
      expect(weather.rainfall, isNotNull);
      expect(weather.uvIndex, isNotNull);
      expect(weather.condition, isNotEmpty);
      expect(weather.description, isNotEmpty);
      expect(weather.timestamp, isNotNull);
      expect(weather.nextUpdate, isNotNull);
    });
  });
}
