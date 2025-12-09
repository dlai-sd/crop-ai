import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/farm/models/farm.dart';
import 'package:crop_ai/features/farm/data/farm_repository.dart';

final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  return MockFarmRepository();
});

final farmsProvider = FutureProvider<List<Farm>>((ref) async {
  final repository = ref.watch(farmRepositoryProvider);
  return repository.getFarms();
});

final farmByIdProvider = FutureProvider.family<Farm?, String>((ref, farmId) async {
  final repository = ref.watch(farmRepositoryProvider);
  return repository.getFarmById(farmId);
});

final farmListNotifierProvider =
    StateNotifierProvider<FarmListNotifier, AsyncValue<List<Farm>>>((ref) {
  final repository = ref.watch(farmRepositoryProvider);
  return FarmListNotifier(repository);
});

class FarmListNotifier extends StateNotifier<AsyncValue<List<Farm>>> {
  final FarmRepository repository;

  FarmListNotifier(this.repository) : super(const AsyncValue.loading()) {
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    try {
      state = const AsyncValue.loading();
      final farms = await repository.getFarms();
      state = AsyncValue.data(farms);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> addFarm(Farm farm) async {
    try {
      await repository.addFarm(farm);
      await _loadFarms();
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> updateFarm(Farm farm) async {
    try {
      await repository.updateFarm(farm);
      await _loadFarms();
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> deleteFarm(String farmId) async {
    try {
      await repository.deleteFarm(farmId);
      await _loadFarms();
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> refresh() => _loadFarms();
}
