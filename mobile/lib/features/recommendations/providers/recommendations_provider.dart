import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/recommendations/models/recommendation.dart';
import 'package:crop_ai/features/recommendations/data/recommendations_repository.dart';
import 'package:crop_ai/features/predictions/providers/prediction_provider.dart';

final recommendationsRepositoryProvider = Provider((ref) {
  return RecommendationsRepository();
});

/// Get treatment recommendations for a farm
final treatmentRecommendationsProvider =
    FutureProvider.family<List<TreatmentRecommendation>, String>((ref, farmId) async {
  final repository = ref.watch(recommendationsRepositoryProvider);

  // Get disease predictions
  final diseasePredict = await ref.watch(diseasePredictionProvider(farmId).future);

  // Extract disease confidences
  final diseaseConfidences = <String, double>{};
  for (var disease in diseasePredict.predictions) {
    diseaseConfidences[disease.label] = disease.confidence;
  }

  return repository.getTreatmentRecommendations(farmId, diseaseConfidences);
});

/// Get yield optimization recommendations
final yieldRecommendationsProvider =
    FutureProvider.family<List<YieldOptimizationRecommendation>, String>((ref, farmId) async {
  final repository = ref.watch(recommendationsRepositoryProvider);

  // Get yield prediction
  final yieldPredict = await ref.watch(yieldPredictionProvider(farmId).future);

  return repository.getYieldRecommendations(
    farmId,
    yieldPredict.prediction.predictedYield,
    yieldPredict.prediction.confidence,
    yieldPredict.prediction.growthStage,
  );
});

/// Get risk alerts for a farm
final riskAlertsProvider = FutureProvider.family<List<RiskAlert>, String>((ref, farmId) async {
  final repository = ref.watch(recommendationsRepositoryProvider);

  // Get predictions
  final diseasePredict = await ref.watch(diseasePredictionProvider(farmId).future);
  final yieldPredict = await ref.watch(yieldPredictionProvider(farmId).future);

  // Extract disease confidences
  final diseaseConfidences = <String, double>{};
  for (var disease in diseasePredict.predictions) {
    diseaseConfidences[disease.label] = disease.confidence;
  }

  return repository.getRiskAlerts(
    farmId,
    diseaseConfidences,
    yieldPredict.prediction.predictedYield,
    'normal', // Mock weather pattern - can be fetched from weather service
  );
});

/// Get combined recommendations dashboard
final recommendationsDashboardProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, farmId) async {
  final repository = ref.watch(recommendationsRepositoryProvider);

  // Get predictions
  final diseasePredict = await ref.watch(diseasePredictionProvider(farmId).future);
  final yieldPredict = await ref.watch(yieldPredictionProvider(farmId).future);

  // Extract disease confidences
  final diseaseConfidences = <String, double>{};
  for (var disease in diseasePredict.predictions) {
    diseaseConfidences[disease.label] = disease.confidence;
  }

  return repository.getAllRecommendations(
    farmId,
    diseaseConfidences,
    yieldPredict.prediction.predictedYield,
    yieldPredict.prediction.confidence,
    yieldPredict.prediction.growthStage,
    'normal',
  );
});

/// Selected treatment recommendation for detail view
final selectedTreatmentProvider = StateProvider<TreatmentRecommendation?>((ref) {
  return null;
});

/// Selected yield recommendation for detail view
final selectedYieldRecommendationProvider = StateProvider<YieldOptimizationRecommendation?>((ref) {
  return null;
});

/// Selected risk alert for detail view
final selectedRiskAlertProvider = StateProvider<RiskAlert?>((ref) {
  return null;
});
