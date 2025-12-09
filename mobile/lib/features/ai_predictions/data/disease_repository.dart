import 'package:crop_ai/database/database.dart';
import 'package:crop_ai/features/ai_predictions/models/disease_prediction.dart';

/// Repository for disease predictions
class DiseaseRepository {
  final Database db;

  DiseaseRepository({required this.db});

  /// Save disease prediction to database
  Future<int> savePrediction(DiseasePrediction prediction) async {
    final companion = DiseasePredictionsCompanion(
      diseaseName: drift.Value(prediction.diseaseName),
      confidence: drift.Value(prediction.confidence),
      severity: drift.Value(prediction.severity),
      treatments: drift.Value(prediction.treatments.join(',')),
      detectionTime: drift.Value(prediction.detectionTime),
      farmId: drift.Value(prediction.farmId),
      photoPath: drift.Value(prediction.photoPath),
      createdAt: drift.Value(DateTime.now()),
    );

    return await db.into(db.diseasePredictions).insert(companion);
  }

  /// Get all predictions for a farm
  Future<List<DiseasePrediction>> getPredictionsForFarm(String farmId) async {
    final query = (db.select(db.diseasePredictions)
      ..where((t) => t.farmId.equals(farmId))
      ..orderBy([(t) => OrderingTerm.desc(t.detectionTime)]));

    final rows = await query.get();
    return rows
        .map((row) => DiseasePrediction(
              diseaseName: row.diseaseName,
              confidence: row.confidence,
              severity: row.severity,
              treatments: row.treatments.split(','),
              detectionTime: row.detectionTime,
              farmId: row.farmId,
              photoPath: row.photoPath,
            ))
        .toList();
  }

  /// Get predictions within date range
  Future<List<DiseasePrediction>> getPredictionsBetween(
    DateTime start,
    DateTime end, {
    String? farmId,
  }) async {
    var query = db.select(db.diseasePredictions)
      ..where((t) => t.detectionTime.isBetweenValues(start, end));

    if (farmId != null) {
      query = db.select(db.diseasePredictions)
        ..where(
          (t) =>
              t.detectionTime.isBetweenValues(start, end) &
              t.farmId.equals(farmId),
        );
    }

    final rows = await query.get();
    return rows
        .map((row) => DiseasePrediction(
              diseaseName: row.diseaseName,
              confidence: row.confidence,
              severity: row.severity,
              treatments: row.treatments.split(','),
              detectionTime: row.detectionTime,
              farmId: row.farmId,
              photoPath: row.photoPath,
            ))
        .toList();
  }

  /// Get latest prediction for a farm
  Future<DiseasePrediction?> getLatestForFarm(String farmId) async {
    final query = (db.select(db.diseasePredictions)
      ..where((t) => t.farmId.equals(farmId))
      ..orderBy([(t) => OrderingTerm.desc(t.detectionTime)])
      ..limit(1));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return DiseasePrediction(
      diseaseName: row.diseaseName,
      confidence: row.confidence,
      severity: row.severity,
      treatments: row.treatments.split(','),
      detectionTime: row.detectionTime,
      farmId: row.farmId,
      photoPath: row.photoPath,
    );
  }

  /// Delete prediction by ID
  Future<bool> deletePrediction(int id) async {
    return await (db.delete(db.diseasePredictions)
          ..where((t) => t.id.equals(id)))
        .go()
        .then((_) => true)
        .catchError((_) => false);
  }

  /// Get statistics for a farm
  Future<Map<String, dynamic>> getStatisticsForFarm(String farmId) async {
    final predictions = await getPredictionsForFarm(farmId);

    if (predictions.isEmpty) {
      return {
        'total_predictions': 0,
        'average_confidence': 0.0,
        'critical_count': 0,
        'high_count': 0,
        'medium_count': 0,
        'low_count': 0,
        'most_common_disease': null,
      };
    }

    final diseaseCount = <String, int>{};
    for (final p in predictions) {
      diseaseCount[p.diseaseName] = (diseaseCount[p.diseaseName] ?? 0) + 1;
    }

    final mostCommon = diseaseCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      'total_predictions': predictions.length,
      'average_confidence':
          predictions.map((p) => p.confidence).reduce((a, b) => a + b) /
              predictions.length,
      'critical_count':
          predictions.where((p) => p.severity == 'Critical').length,
      'high_count': predictions.where((p) => p.severity == 'High').length,
      'medium_count':
          predictions.where((p) => p.severity == 'Medium').length,
      'low_count': predictions.where((p) => p.severity == 'Low').length,
      'most_common_disease': mostCommon,
    };
  }

  /// Clear all predictions for a farm
  Future<void> clearFarmPredictions(String farmId) async {
    await (db.delete(db.diseasePredictions)
          ..where((t) => t.farmId.equals(farmId)))
        .go();
  }
}
