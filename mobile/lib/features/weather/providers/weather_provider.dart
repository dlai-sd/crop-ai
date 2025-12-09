import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai_mobile/features/weather/models/weather.dart';
import 'package:crop_ai_mobile/features/weather/data/weather_repository.dart';

// Weather repository provider
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return MockWeatherRepository();
});

// Get current weather for a farm
final weatherProvider = FutureProvider.family<Weather, String>((ref, farmId) async {
  final repository = ref.watch(weatherRepositoryProvider);
  return repository.getWeatherByFarmId(farmId);
});

// Get weather forecast for a farm
final weatherForecastProvider = FutureProvider.family<List<Weather>, String>(
  (ref, farmId) async {
    final repository = ref.watch(weatherRepositoryProvider);
    return repository.getForecastByFarmId(farmId);
  },
);

// Get historical weather data
final historicalWeatherProvider =
    FutureProvider.family<List<Weather>, (String, DateTime, DateTime)>(
  (ref, params) async {
    final (farmId, startDate, endDate) = params;
    final repository = ref.watch(weatherRepositoryProvider);
    return repository.getHistoricalWeatherByFarmId(
      farmId,
      startDate: startDate,
      endDate: endDate,
    );
  },
);

// Weather update notifier for manual refreshes
class WeatherNotifier extends StateNotifier<AsyncValue<Weather>> {
  final WeatherRepository _repository;
  final String _farmId;

  WeatherNotifier(this._repository, this._farmId)
      : super(const AsyncValue.loading()) {
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getWeatherByFarmId(_farmId));
  }

  Future<void> refresh() async {
    await _loadWeather();
  }
}

// Weather notifier provider
final weatherNotifierProvider =
    StateNotifierProvider.family<WeatherNotifier, AsyncValue<Weather>, String>(
  (ref, farmId) {
    final repository = ref.watch(weatherRepositoryProvider);
    return WeatherNotifier(repository, farmId);
  },
);
