import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/database/database.dart';
import 'package:crop_ai/features/ai_predictions/data/ml_service.dart';
import 'package:crop_ai/features/ai_predictions/data/disease_repository.dart';
import 'package:crop_ai/features/ai_predictions/models/disease_prediction.dart';

// ML Service provider
final mlServiceProvider = Provider<MLService>((ref) {
  return MockMLService();
});

// Database provider
final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('Database provider must be overridden');
});

// Disease repository provider
final diseaseRepositoryProvider = Provider<DiseaseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DiseaseRepository(db: db);
});

// Current disease prediction (from latest detection)
final currentDiseasePredictionProvider = FutureProvider.family<
    DiseasePrediction?,
    String>((ref, farmId) async {
  final repository = ref.watch(diseaseRepositoryProvider);
  return await repository.getLatestForFarm(farmId);
});

// Disease predictions for farm
final farmDiseasePredictionsProvider = FutureProvider.family<
    List<DiseasePrediction>,
    String>((ref, farmId) async {
  final repository = ref.watch(diseaseRepositoryProvider);
  return await repository.getPredictionsForFarm(farmId);
});

// Disease statistics for farm
final farmDiseaseStatsProvider = FutureProvider.family<
    Map<String, dynamic>,
    String>((ref, farmId) async {
  final repository = ref.watch(diseaseRepositoryProvider);
  return await repository.getStatisticsForFarm(farmId);
});

// Run disease detection
final runDiseaseDetectionProvider = FutureProvider.family<
    DiseasePrediction,
    DiseaseDetectionInput>((ref, input) async {
  final mlService = ref.watch(mlServiceProvider);
  
  // Run inference
  final result = await mlService.predictDisease(input.imageBytes);
  
  // Create prediction object
  final prediction = DiseasePrediction.fromInference(
    result,
    photoPath: input.photoPath,
    farmId: input.farmId,
  );
  
  // Save to repository
  final repository = ref.watch(diseaseRepositoryProvider);
  await repository.savePrediction(prediction);
  
  // Invalidate cache
  ref.invalidate(farmDiseasePredictionsProvider);
  ref.invalidate(currentDiseasePredictionProvider);
  ref.invalidate(farmDiseaseStatsProvider);
  
  return prediction;
});

// Input class for disease detection
class DiseaseDetectionInput {
  final Uint8List imageBytes;
  final String? photoPath;
  final String? farmId;

  DiseaseDetectionInput({
    required this.imageBytes,
    this.photoPath,
    this.farmId,
  });
}
