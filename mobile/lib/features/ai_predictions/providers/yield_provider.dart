import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/ai_predictions/data/disease_repository.dart';
import 'package:crop_ai/features/ai_predictions/data/yield_repository.dart';
import 'package:crop_ai/features/ai_predictions/data/ml_service.dart';
import 'package:crop_ai/features/ai_predictions/models/yield_prediction.dart';
import 'package:crop_ai/features/ai_predictions/providers/disease_provider.dart';

// Yield repository provider
final yieldRepositoryProvider = Provider<YieldRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return YieldRepository(db: db);
});

// Current yield prediction (from latest forecast)
final currentYieldPredictionProvider = FutureProvider.family<
    YieldPrediction?,
    String>((ref, farmId) async {
  final repository = ref.watch(yieldRepositoryProvider);
  return await repository.getLatestForFarm(farmId);
});

// Yield predictions for farm
final farmYieldPredictionsProvider = FutureProvider.family<
    List<YieldPrediction>,
    String>((ref, farmId) async {
  final repository = ref.watch(yieldRepositoryProvider);
  return await repository.getPredictionsForFarm(farmId);
});

// Yield statistics for farm
final farmYieldStatsProvider = FutureProvider.family<
    Map<String, dynamic>,
    String>((ref, farmId) async {
  final repository = ref.watch(yieldRepositoryProvider);
  return await repository.getStatisticsForFarm(farmId);
});

// Yield trend analysis
final yieldTrendProvider = FutureProvider.family<
    Map<String, dynamic>,
    String>((ref, farmId) async {
  final repository = ref.watch(yieldRepositoryProvider);
  return await repository.getYieldTrend(farmId);
});

// Average yield over period
final averageYieldProvider = FutureProvider.family<
    double,
    YieldAnalysisPeriod>((ref, period) async {
  final repository = ref.watch(yieldRepositoryProvider);
  return await repository.getAverageYield(
    period.farmId,
    start: period.startDate,
    end: period.endDate,
  );
});

// Confidence trend
final yieldConfidenceTrendProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    String>((ref, farmId) async {
  final repository = ref.watch(yieldRepositoryProvider);
  return await repository.getConfidenceTrend(farmId);
});

// Run yield prediction
final runYieldPredictionProvider = FutureProvider.family<
    YieldPrediction,
    YieldPredictionInput>((ref, input) async {
  final mlService = ref.watch(mlServiceProvider);
  
  // Normalize features
  final normalizedFeatures = FeatureEngineer.normalizeFeatures(input.features);
  
  // Run inference
  final result = await mlService.predictYield(normalizedFeatures);
  
  // Create prediction object
  final prediction = YieldPrediction.fromInference(result);
  
  // Save to repository
  final repository = ref.watch(yieldRepositoryProvider);
  await repository.savePrediction(prediction);
  
  // Invalidate cache
  ref.invalidate(farmYieldPredictionsProvider);
  ref.invalidate(currentYieldPredictionProvider);
  ref.invalidate(farmYieldStatsProvider);
  ref.invalidate(yieldTrendProvider);
  ref.invalidate(averageYieldProvider);
  
  return prediction;
});

// Input classes for yield analysis
class YieldPredictionInput {
  final List<double> features;
  final String? farmId;

  YieldPredictionInput({
    required this.features,
    this.farmId,
  });
}

class YieldAnalysisPeriod {
  final String farmId;
  final DateTime startDate;
  final DateTime endDate;

  YieldAnalysisPeriod({
    required this.farmId,
    required this.startDate,
    required this.endDate,
  });
}
