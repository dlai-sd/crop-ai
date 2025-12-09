import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/analytics/data/analytics_repository.dart';
import 'package:crop_ai/features/analytics/models/analytics_summary.dart';
import 'package:crop_ai/features/ai_predictions/providers/disease_provider.dart';

// Analytics repository provider
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final diseaseRepo = ref.watch(diseaseRepositoryProvider);
  final yieldRepo = ref.watch(yieldRepositoryProvider);
  final stageRepo = ref.watch(growthStageRepositoryProvider);
  final db = ref.watch(databaseProvider);

  return AnalyticsRepository(
    db: db,
    diseaseRepo: diseaseRepo,
    yieldRepo: yieldRepo,
    stageRepo: stageRepo,
  );
});

// Analytics summary
final analyticsSummaryProvider = FutureProvider.family<
    AnalyticsSummary,
    String>((ref, farmId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getSummaryForFarm(farmId);
});

// Disease trend (30 days)
final diseaseTrendProvider = FutureProvider.family<
    List<TrendData>,
    String>((ref, farmId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getDiseaseTrend(farmId);
});

// Yield trend (5 seasons)
final yieldTrendChartProvider = FutureProvider.family<
    List<TrendData>,
    String>((ref, farmId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getYieldTrend(farmId);
});

// Disease severity distribution
final diseaseSeverityProvider = FutureProvider.family<
    List<ChartDataPoint>,
    String>((ref, farmId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getDiseaseSeverityDistribution(farmId);
});

// Most common diseases
final commonDiseasesProvider = FutureProvider.family<
    List<ChartDataPoint>,
    String>((ref, farmId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getMostCommonDiseases(farmId);
});

// Yield confidence trend
final yieldConfidenceProvider = FutureProvider.family<
    List<ChartDataPoint>,
    String>((ref, farmId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getYieldConfidenceTrend(farmId);
});

// Growth stage timeline
final growthTimelineProvider = FutureProvider.family<
    List<ChartDataPoint>,
    String>((ref, farmId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getGrowthStageTimeline(farmId);
});

// Key metrics
final keyMetricsProvider = FutureProvider.family<
    Map<String, dynamic>,
    String>((ref, farmId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.getKeyMetrics(farmId);
});

// Farm comparison
final farmComparisonProvider = FutureProvider.family<
    List<ChartDataPoint>,
    List<String>>((ref, farmIds) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return await repo.compareFarmsYield(farmIds);
});
