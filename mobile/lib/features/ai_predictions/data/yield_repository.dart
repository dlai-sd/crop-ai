import 'package:crop_ai/database/database.dart';
import 'package:crop_ai/features/ai_predictions/models/yield_prediction.dart';

/// Repository for yield predictions/forecasts
class YieldRepository {
  final Database db;

  YieldRepository({required this.db});

  /// Save yield prediction to database
  Future<int> savePrediction(YieldPrediction prediction) async {
    final companion = YieldPredictionsCompanion(
      estimatedYield: drift.Value(prediction.estimatedYield),
      lowerBound: drift.Value(prediction.lowerBound),
      upperBound: drift.Value(prediction.upperBound),
      confidence: drift.Value(prediction.confidence),
      riskFactors: drift.Value(prediction.riskFactors.join(',')),
      opportunities: drift.Value(prediction.opportunities.join(',')),
      farmId: drift.Value(null), // Will be set from context
      predictedAt: drift.Value(DateTime.now()),
      createdAt: drift.Value(DateTime.now()),
    );

    return await db.into(db.yieldPredictions).insert(companion);
  }

  /// Get all predictions for a farm
  Future<List<YieldPrediction>> getPredictionsForFarm(String farmId) async {
    final query = (db.select(db.yieldPredictions)
      ..where((t) => t.farmId.equals(farmId))
      ..orderBy([(t) => OrderingTerm.desc(t.predictedAt)]));

    final rows = await query.get();
    return rows
        .map((row) => YieldPrediction(
              estimatedYield: row.estimatedYield,
              lowerBound: row.lowerBound,
              upperBound: row.upperBound,
              confidence: row.confidence,
              riskFactors: row.riskFactors.split(','),
              opportunities: row.opportunities.split(','),
            ))
        .toList();
  }

  /// Get predictions within date range
  Future<List<YieldPrediction>> getPredictionsBetween(
    DateTime start,
    DateTime end, {
    String? farmId,
  }) async {
    var query = db.select(db.yieldPredictions)
      ..where((t) => t.predictedAt.isBetweenValues(start, end));

    if (farmId != null) {
      query = db.select(db.yieldPredictions)
        ..where(
          (t) =>
              t.predictedAt.isBetweenValues(start, end) &
              t.farmId.equals(farmId),
        );
    }

    final rows = await query.get();
    return rows
        .map((row) => YieldPrediction(
              estimatedYield: row.estimatedYield,
              lowerBound: row.lowerBound,
              upperBound: row.upperBound,
              confidence: row.confidence,
              riskFactors: row.riskFactors.split(','),
              opportunities: row.opportunities.split(','),
            ))
        .toList();
  }

  /// Get latest prediction for a farm
  Future<YieldPrediction?> getLatestForFarm(String farmId) async {
    final query = (db.select(db.yieldPredictions)
      ..where((t) => t.farmId.equals(farmId))
      ..orderBy([(t) => OrderingTerm.desc(t.predictedAt)])
      ..limit(1));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return YieldPrediction(
      estimatedYield: row.estimatedYield,
      lowerBound: row.lowerBound,
      upperBound: row.upperBound,
      confidence: row.confidence,
      riskFactors: row.riskFactors.split(','),
      opportunities: row.opportunities.split(','),
    );
  }

  /// Get average yield over time period
  Future<double> getAverageYield(
    String farmId, {
    required DateTime start,
    required DateTime end,
  }) async {
    final predictions = await getPredictionsBetween(start, end, farmId: farmId);
    if (predictions.isEmpty) return 0.0;

    return predictions.map((p) => p.estimatedYield).reduce((a, b) => a + b) /
        predictions.length;
  }

  /// Get yield trend (comparison between consecutive predictions)
  Future<Map<String, dynamic>> getYieldTrend(String farmId) async {
    final predictions = await getPredictionsForFarm(farmId);
    if (predictions.length < 2) {
      return {'trend': 'insufficient_data', 'change_percent': 0.0};
    }

    final latest = predictions.first.estimatedYield;
    final previous = predictions[1].estimatedYield;
    final changePercent = ((latest - previous) / previous) * 100;

    return {
      'trend': changePercent > 0 ? 'increasing' : 'decreasing',
      'change_percent': changePercent,
      'current_yield': latest,
      'previous_yield': previous,
    };
  }

  /// Get statistics for a farm
  Future<Map<String, dynamic>> getStatisticsForFarm(String farmId) async {
    final predictions = await getPredictionsForFarm(farmId);

    if (predictions.isEmpty) {
      return {
        'total_predictions': 0,
        'average_yield': 0.0,
        'min_yield': 0.0,
        'max_yield': 0.0,
        'average_confidence': 0.0,
        'reliable_predictions': 0,
      };
    }

    final yields = predictions.map((p) => p.estimatedYield).toList();
    final confidences = predictions.map((p) => p.confidence).toList();

    return {
      'total_predictions': predictions.length,
      'average_yield': yields.reduce((a, b) => a + b) / yields.length,
      'min_yield': yields.reduce((a, b) => a < b ? a : b),
      'max_yield': yields.reduce((a, b) => a > b ? a : b),
      'average_confidence':
          confidences.reduce((a, b) => a + b) / confidences.length,
      'reliable_predictions':
          predictions.where((p) => p.isReliable).length,
    };
  }

  /// Delete prediction by ID
  Future<bool> deletePrediction(int id) async {
    return await (db.delete(db.yieldPredictions)
          ..where((t) => t.id.equals(id)))
        .go()
        .then((_) => true)
        .catchError((_) => false);
  }

  /// Clear all predictions for a farm
  Future<void> clearFarmPredictions(String farmId) async {
    await (db.delete(db.yieldPredictions)
          ..where((t) => t.farmId.equals(farmId)))
        .go();
  }

  /// Get confidence trend (how model confidence changes over time)
  Future<List<Map<String, dynamic>>> getConfidenceTrend(String farmId) async {
    final predictions = await getPredictionsForFarm(farmId);
    return predictions
        .map((p) => {
              'yield': p.estimatedYield,
              'confidence': p.confidence,
              'is_reliable': p.isReliable,
              'interval_width': p.intervalWidth,
            })
        .toList();
  }
}
