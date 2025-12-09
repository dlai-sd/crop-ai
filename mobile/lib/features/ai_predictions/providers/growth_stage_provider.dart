import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/ai_predictions/data/growth_stage_repository.dart';
import 'package:crop_ai/features/ai_predictions/data/ml_service.dart';
import 'package:crop_ai/features/ai_predictions/models/growth_stage_prediction.dart';
import 'package:crop_ai/features/ai_predictions/providers/disease_provider.dart';

// Growth stage repository provider
final growthStageRepositoryProvider = Provider<GrowthStageRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return GrowthStageRepository(db: db);
});

// Current growth stage prediction
final currentGrowthStageProvider = FutureProvider.family<
    GrowthStagePrediction?,
    String>((ref, farmId) async {
  final repository = ref.watch(growthStageRepositoryProvider);
  return await repository.getLatestForFarm(farmId);
});

// Growth stage predictions for farm
final farmGrowthStagePredictionsProvider = FutureProvider.family<
    List<GrowthStagePrediction>,
    String>((ref, farmId) async {
  final repository = ref.watch(growthStageRepositoryProvider);
  return await repository.getPredictionsForFarm(farmId);
});

// Growth stage statistics
final farmGrowthStageStatsProvider = FutureProvider.family<
    Map<String, dynamic>,
    String>((ref, farmId) async {
  final repository = ref.watch(growthStageRepositoryProvider);
  return await repository.getStatisticsForFarm(farmId);
});

// Growth progression over time
final growthProgressionProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    String>((ref, farmId) async {
  final repository = ref.watch(growthStageRepositoryProvider);
  return await repository.getGrowthProgression(farmId);
});

// Current stage info with estimates
final currentStageInfoProvider = FutureProvider.family<
    Map<String, dynamic>?,
    String>((ref, farmId) async {
  final repository = ref.watch(growthStageRepositoryProvider);
  return await repository.getCurrentStageInfo(farmId);
});

// Observed stages for farm
final observedStagesProvider = FutureProvider.family<
    List<GrowthStage>,
    String>((ref, farmId) async {
  final repository = ref.watch(growthStageRepositoryProvider);
  return await repository.getObservedStages(farmId);
});

// Harvest date estimation
final estimatedHarvestDateProvider = FutureProvider.family<
    DateTime?,
    String>((ref, farmId) async {
  final repository = ref.watch(growthStageRepositoryProvider);
  return await repository.estimateHarvestDate(farmId);
});

// Stage transitions history
final stageTransitionsProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    String>((ref, farmId) async {
  final repository = ref.watch(growthStageRepositoryProvider);
  return await repository.getStageTransitions(farmId);
});

// Run growth stage prediction
final runGrowthStagePredictionProvider = FutureProvider.family<
    GrowthStagePrediction,
    GrowthStagePredictionInput>((ref, input) async {
  final mlService = ref.watch(mlServiceProvider);
  
  // Run inference
  final result = await mlService.predictGrowthStage(input.imageBytes);
  
  // Create prediction object
  final prediction = GrowthStagePrediction.fromInference(result);
  
  // Save to repository
  final repository = ref.watch(growthStageRepositoryProvider);
  await repository.savePrediction(prediction);
  
  // Invalidate cache
  ref.invalidate(farmGrowthStagePredictionsProvider);
  ref.invalidate(currentGrowthStageProvider);
  ref.invalidate(farmGrowthStageStatsProvider);
  ref.invalidate(growthProgressionProvider);
  ref.invalidate(currentStageInfoProvider);
  ref.invalidate(observedStagesProvider);
  ref.invalidate(estimatedHarvestDateProvider);
  ref.invalidate(stageTransitionsProvider);
  
  return prediction;
});

// Input class for growth stage prediction
class GrowthStagePredictionInput {
  final Uint8List imageBytes;
  final String? photoPath;
  final String? farmId;

  GrowthStagePredictionInput({
    required this.imageBytes,
    this.photoPath,
    this.farmId,
  });
}
