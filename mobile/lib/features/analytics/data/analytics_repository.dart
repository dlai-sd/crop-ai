import 'package:crop_ai/database/database.dart';
import 'package:crop_ai/features/analytics/models/analytics_summary.dart';
import 'package:crop_ai/features/ai_predictions/data/disease_repository.dart';
import 'package:crop_ai/features/ai_predictions/data/yield_repository.dart';
import 'package:crop_ai/features/ai_predictions/data/growth_stage_repository.dart';

class AnalyticsRepository {
  final Database db;
  final DiseaseRepository diseaseRepo;
  final YieldRepository yieldRepo;
  final GrowthStageRepository stageRepo;

  AnalyticsRepository({
    required this.db,
    required this.diseaseRepo,
    required this.yieldRepo,
    required this.stageRepo,
  });

  /// Get analytics summary for a farm
  Future<AnalyticsSummary> getSummaryForFarm(String farmId) async {
    final diseases = await diseaseRepo.getPredictionsForFarm(farmId);
    final yields = await yieldRepo.getPredictionsForFarm(farmId);
    final stages = await stageRepo.getPredictionsForFarm(farmId);

    return AnalyticsSummary.fromData(
      farmId: farmId,
      diseases: diseases,
      yields: yields,
      stages: stages,
    );
  }

  /// Get disease trend (last 30 days)
  Future<List<TrendData>> getDiseaseTrend(String farmId) async {
    final startDate = DateTime.now().subtract(Duration(days: 30));
    final endDate = DateTime.now();

    final diseases = await diseaseRepo.getPredictionsBetween(
      startDate,
      endDate,
      farmId: farmId,
    );

    // Group by date
    final grouped = <String, List<dynamic>>{};
    for (final d in diseases) {
      final dateStr =
          '${d.detectionTime.year}-${d.detectionTime.month}-${d.detectionTime.day}';
      grouped[dateStr] = (grouped[dateStr] ?? [])..add(d);
    }

    return grouped.entries
        .map((e) {
          final avgConfidence =
              (e.value as List).cast<dynamic>().fold<double>(
                    0,
                    (sum, d) => sum + (d.confidence as double),
                  ) /
                  (e.value as List).length;

          return TrendData(
            date: DateTime.parse(e.key),
            value: avgConfidence,
            label: e.key,
          );
        })
        .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get yield trend (last 5 seasons)
  Future<List<TrendData>> getYieldTrend(String farmId) async {
    final yields = await yieldRepo.getPredictionsForFarm(farmId);

    if (yields.isEmpty) return [];

    return List.generate(
      yields.length > 5 ? 5 : yields.length,
      (i) => TrendData(
        date: DateTime.now().subtract(Duration(days: 30 * (i + 1))),
        value: yields[i].estimatedYield,
        label: 'Season ${yields.length - i}',
      ),
    );
  }

  /// Get disease severity distribution
  Future<List<ChartDataPoint>> getDiseaseSeverityDistribution(
    String farmId,
  ) async {
    final stats = await diseaseRepo.getStatisticsForFarm(farmId);

    return [
      ChartDataPoint(
        label: 'Critical',
        value: (stats['critical_count'] as int).toDouble(),
        color: '#FF5252',
      ),
      ChartDataPoint(
        label: 'High',
        value: (stats['high_count'] as int).toDouble(),
        color: '#FF9800',
      ),
      ChartDataPoint(
        label: 'Medium',
        value: (stats['medium_count'] as int).toDouble(),
        color: '#FFC107',
      ),
      ChartDataPoint(
        label: 'Low',
        value: (stats['low_count'] as int).toDouble(),
        color: '#4CAF50',
      ),
    ];
  }

  /// Get most common diseases
  Future<List<ChartDataPoint>> getMostCommonDiseases(
    String farmId, {
    int limit = 5,
  }) async {
    final diseases = await diseaseRepo.getPredictionsForFarm(farmId);

    if (diseases.isEmpty) return [];

    final diseaseCount = <String, int>{};
    for (final d in diseases) {
      diseaseCount[d.diseaseName] = (diseaseCount[d.diseaseName] ?? 0) + 1;
    }

    return diseaseCount.entries
        .sorted((a, b) => b.value.compareTo(a.value))
        .take(limit)
        .map((e) => ChartDataPoint(
              label: e.key,
              value: e.value.toDouble(),
            ))
        .toList();
  }

  /// Get yield confidence trend
  Future<List<ChartDataPoint>> getYieldConfidenceTrend(String farmId) async {
    final trends = await yieldRepo.getConfidenceTrend(farmId);

    if (trends.isEmpty) return [];

    return List.generate(
      trends.length > 10 ? 10 : trends.length,
      (i) => ChartDataPoint(
        label: 'P${i + 1}',
        value: (trends[i]['confidence'] as double) * 100,
      ),
    );
  }

  /// Get growth stage timeline
  Future<List<ChartDataPoint>> getGrowthStageTimeline(String farmId) async {
    final progression = await stageRepo.getGrowthProgression(farmId);

    return progression
        .asMap()
        .entries
        .map((e) => ChartDataPoint(
              label: e.value['stage'] as String,
              value: e.key.toDouble(),
            ))
        .toList();
  }

  /// Get key metrics card data
  Future<Map<String, dynamic>> getKeyMetrics(String farmId) async {
    final diseaseStats = await diseaseRepo.getStatisticsForFarm(farmId);
    final yieldStats = await yieldRepo.getStatisticsForFarm(farmId);
    final stageInfo = await stageRepo.getCurrentStageInfo(farmId);

    return {
      'totalDiseases': diseaseStats['total_predictions'],
      'avgYield':
          (yieldStats['average_yield'] as double).toStringAsFixed(0),
      'currentStage': stageInfo?['current_stage'] ?? 'Unknown',
      'daysToHarvest': stageInfo?['estimated_days_to_next'] ?? 90,
      'reliableYields': yieldStats['reliable_predictions'],
      'criticalDiseases': diseaseStats['critical_count'],
    };
  }

  /// Get farm comparison data
  Future<List<ChartDataPoint>> compareFarmsYield(List<String> farmIds) async {
    final data = <ChartDataPoint>[];

    for (final farmId in farmIds) {
      final stats = await yieldRepo.getStatisticsForFarm(farmId);
      data.add(ChartDataPoint(
        label: farmId,
        value: stats['average_yield'] as double,
      ));
    }

    return data;
  }
}

extension _SortedExtension<T> on Iterable<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final list = toList();
    list.sort(compare);
    return list;
  }
}
