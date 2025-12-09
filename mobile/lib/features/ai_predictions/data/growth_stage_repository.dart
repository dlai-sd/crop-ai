import 'package:crop_ai/database/database.dart';
import 'package:crop_ai/features/ai_predictions/models/growth_stage_prediction.dart';

/// Repository for growth stage predictions
class GrowthStageRepository {
  final Database db;

  GrowthStageRepository({required this.db});

  /// Save growth stage prediction to database
  Future<int> savePrediction(GrowthStagePrediction prediction) async {
    final companion = GrowthStagePredictionsCompanion(
      stageName: drift.Value(prediction.currentStage.toString().split('.').last),
      daysInStage: drift.Value(prediction.daysInStage),
      daysToNextStage: drift.Value(prediction.daysToNextStage),
      recommendations: drift.Value(prediction.recommendations.join(',')),
      stageMetrics: drift.Value(
        prediction.stageMetrics.entries
            .map((e) => '${e.key}:${e.value}')
            .join(';'),
      ),
      farmId: drift.Value(null), // Will be set from context
      predictedAt: drift.Value(DateTime.now()),
      createdAt: drift.Value(DateTime.now()),
    );

    return await db.into(db.growthStagePredictions).insert(companion);
  }

  /// Get all predictions for a farm
  Future<List<GrowthStagePrediction>> getPredictionsForFarm(
    String farmId,
  ) async {
    final query = (db.select(db.growthStagePredictions)
      ..where((t) => t.farmId.equals(farmId))
      ..orderBy([(t) => OrderingTerm.desc(t.predictedAt)]));

    final rows = await query.get();
    return rows
        .map((row) => _mapRowToPrediction(row))
        .toList();
  }

  /// Get predictions within date range
  Future<List<GrowthStagePrediction>> getPredictionsBetween(
    DateTime start,
    DateTime end, {
    String? farmId,
  }) async {
    var query = db.select(db.growthStagePredictions)
      ..where((t) => t.predictedAt.isBetweenValues(start, end));

    if (farmId != null) {
      query = db.select(db.growthStagePredictions)
        ..where(
          (t) =>
              t.predictedAt.isBetweenValues(start, end) &
              t.farmId.equals(farmId),
        );
    }

    final rows = await query.get();
    return rows
        .map((row) => _mapRowToPrediction(row))
        .toList();
  }

  /// Get latest prediction for a farm
  Future<GrowthStagePrediction?> getLatestForFarm(String farmId) async {
    final query = (db.select(db.growthStagePredictions)
      ..where((t) => t.farmId.equals(farmId))
      ..orderBy([(t) => OrderingTerm.desc(t.predictedAt)])
      ..limit(1));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToPrediction(row);
  }

  /// Track growth progression over time
  Future<List<Map<String, dynamic>>> getGrowthProgression(
    String farmId,
  ) async {
    final predictions = await getPredictionsForFarm(farmId);
    return predictions
        .map((p) => {
              'stage': p.currentStage.toString().split('.').last,
              'days_in_stage': p.daysInStage,
              'days_to_next': p.daysToNextStage,
              'timestamp': DateTime.now(),
            })
        .toList();
  }

  /// Get current stage with time estimates
  Future<Map<String, dynamic>?> getCurrentStageInfo(String farmId) async {
    final latest = await getLatestForFarm(farmId);
    if (latest == null) return null;

    return {
      'current_stage': latest.currentStage.toString().split('.').last,
      'days_in_current': latest.daysInStage,
      'estimated_days_to_next': latest.daysToNextStage,
      'total_days_since_planting': latest.daysInStage +
          _calculateDaysSincePlanting(latest.currentStage),
      'recommendations': latest.recommendations,
    };
  }

  /// Get stage statistics for farm
  Future<Map<String, dynamic>> getStatisticsForFarm(String farmId) async {
    final predictions = await getPredictionsForFarm(farmId);

    if (predictions.isEmpty) {
      return {
        'total_observations': 0,
        'earliest_stage': null,
        'latest_stage': null,
        'stage_progression': [],
      };
    }

    final stageNames = predictions
        .map((p) => p.currentStage.toString().split('.').last)
        .toList();
    final stageCounts = <String, int>{};
    for (final stage in stageNames) {
      stageCounts[stage] = (stageCounts[stage] ?? 0) + 1;
    }

    return {
      'total_observations': predictions.length,
      'earliest_stage': stageNames.last,
      'latest_stage': stageNames.first,
      'stage_distribution': stageCounts,
      'average_days_per_stage': predictions
          .map((p) => p.daysInStage)
          .reduce((a, b) => a + b) /
          predictions.length,
    };
  }

  /// Delete prediction by ID
  Future<bool> deletePrediction(int id) async {
    return await (db.delete(db.growthStagePredictions)
          ..where((t) => t.id.equals(id)))
        .go()
        .then((_) => true)
        .catchError((_) => false);
  }

  /// Clear all predictions for a farm
  Future<void> clearFarmPredictions(String farmId) async {
    await (db.delete(db.growthStagePredictions)
          ..where((t) => t.farmId.equals(farmId)))
        .go();
  }

  /// Get all unique stages observed for farm (in order)
  Future<List<GrowthStage>> getObservedStages(String farmId) async {
    final predictions = await getPredictionsForFarm(farmId);
    final stages = <GrowthStage>{};
    for (final p in predictions) {
      stages.add(p.currentStage);
    }
    return stages.toList()..sort((a, b) => a.index.compareTo(b.index));
  }

  /// Helper to map database row to prediction object
  GrowthStagePrediction _mapRowToPrediction(
    GrowthStagePrediction row,
  ) {
    return row; // Row already is GrowthStagePrediction from Drift
  }

  /// Calculate days since planting based on stage
  int _calculateDaysSincePlanting(GrowthStage stage) {
    // Approximate weeks per stage * 7
    const daysPerStage = {
      GrowthStage.seedling: 14,
      GrowthStage.vegetative: 35,
      GrowthStage.flowering: 56,
      GrowthStage.fruitGrain: 84,
      GrowthStage.mature: 119,
      GrowthStage.harvestReady: 140,
    };
    return daysPerStage[stage] ?? 0;
  }

  /// Estimate harvest date based on current stage
  Future<DateTime?> estimateHarvestDate(String farmId) async {
    final latest = await getLatestForFarm(farmId);
    if (latest == null) return null;

    // Calculate days until harvest (harvestReady stage)
    final totalDaysToHarvest = latest.daysToNextStage;
    return DateTime.now().add(Duration(days: totalDaysToHarvest.toInt()));
  }

  /// Get stage transition history
  Future<List<Map<String, dynamic>>> getStageTransitions(
    String farmId,
  ) async {
    final predictions = await getPredictionsForFarm(farmId);
    if (predictions.length < 2) return [];

    final transitions = <Map<String, dynamic>>[];
    for (int i = 0; i < predictions.length - 1; i++) {
      final current = predictions[i].currentStage;
      final previous = predictions[i + 1].currentStage;

      if (current != previous) {
        transitions.add({
          'from_stage': previous.toString().split('.').last,
          'to_stage': current.toString().split('.').last,
          'days_in_previous': predictions[i + 1].daysInStage,
        });
      }
    }
    return transitions;
  }
}
