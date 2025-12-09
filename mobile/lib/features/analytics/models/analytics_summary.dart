import 'package:crop_ai/features/ai_predictions/models/disease_prediction.dart';
import 'package:crop_ai/features/ai_predictions/models/yield_prediction.dart';
import 'package:crop_ai/features/ai_predictions/models/growth_stage_prediction.dart';

class AnalyticsSummary {
  final String farmId;
  final DateTime generatedAt;
  
  // Disease metrics
  final int totalDiseases;
  final int criticalCount;
  final int averageConfidence;
  final String mostCommonDisease;
  
  // Yield metrics
  final double averageYield;
  final double yieldTrend;
  final bool yieldIncreasing;
  
  // Growth metrics
  final String currentStage;
  final DateTime estimatedHarvest;
  final int daysToHarvest;

  const AnalyticsSummary({
    required this.farmId,
    required this.generatedAt,
    required this.totalDiseases,
    required this.criticalCount,
    required this.averageConfidence,
    required this.mostCommonDisease,
    required this.averageYield,
    required this.yieldTrend,
    required this.yieldIncreasing,
    required this.currentStage,
    required this.estimatedHarvest,
    required this.daysToHarvest,
  });

  factory AnalyticsSummary.fromData({
    required String farmId,
    required List<DiseasePrediction> diseases,
    required List<YieldPrediction> yields,
    required List<GrowthStagePrediction> stages,
  }) {
    final diseaseStats = _computeDiseaseStats(diseases);
    final yieldStats = _computeYieldStats(yields);
    final stageInfo = _computeStageInfo(stages);

    return AnalyticsSummary(
      farmId: farmId,
      generatedAt: DateTime.now(),
      totalDiseases: diseaseStats['total'] as int,
      criticalCount: diseaseStats['critical'] as int,
      averageConfidence: (diseaseStats['avgConfidence'] as double).toInt(),
      mostCommonDisease: diseaseStats['mostCommon'] as String,
      averageYield: yieldStats['average'] as double,
      yieldTrend: yieldStats['trend'] as double,
      yieldIncreasing: yieldStats['increasing'] as bool,
      currentStage: stageInfo['stage'] as String,
      estimatedHarvest: stageInfo['harvestDate'] as DateTime,
      daysToHarvest: stageInfo['daysToHarvest'] as int,
    );
  }

  static Map<String, dynamic> _computeDiseaseStats(
    List<DiseasePrediction> diseases,
  ) {
    if (diseases.isEmpty) {
      return {
        'total': 0,
        'critical': 0,
        'avgConfidence': 0.0,
        'mostCommon': 'None',
      };
    }

    final diseaseCount = <String, int>{};
    int critical = 0;
    double totalConfidence = 0;

    for (final d in diseases) {
      diseaseCount[d.diseaseName] = (diseaseCount[d.diseaseName] ?? 0) + 1;
      if (d.severity == 'Critical') critical++;
      totalConfidence += d.confidence;
    }

    final mostCommon = diseaseCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      'total': diseases.length,
      'critical': critical,
      'avgConfidence': totalConfidence / diseases.length,
      'mostCommon': mostCommon,
    };
  }

  static Map<String, dynamic> _computeYieldStats(
    List<YieldPrediction> yields,
  ) {
    if (yields.isEmpty) {
      return {
        'average': 0.0,
        'trend': 0.0,
        'increasing': false,
      };
    }

    if (yields.length == 1) {
      return {
        'average': yields[0].estimatedYield,
        'trend': 0.0,
        'increasing': false,
      };
    }

    final average = yields.map((y) => y.estimatedYield).reduce((a, b) => a + b) /
        yields.length;
    final latest = yields[0].estimatedYield;
    final previous = yields[1].estimatedYield;
    final trend = ((latest - previous) / previous) * 100;

    return {
      'average': average,
      'trend': trend.abs(),
      'increasing': trend > 0,
    };
  }

  static Map<String, dynamic> _computeStageInfo(
    List<GrowthStagePrediction> stages,
  ) {
    if (stages.isEmpty) {
      return {
        'stage': 'Unknown',
        'harvestDate': DateTime.now().add(Duration(days: 90)),
        'daysToHarvest': 90,
      };
    }

    final latest = stages.first;
    final harvestDate = DateTime.now().add(
      Duration(days: latest.daysToNextStage.toInt()),
    );

    return {
      'stage': latest.currentStage.toString().split('.').last,
      'harvestDate': harvestDate,
      'daysToHarvest': latest.daysToNextStage.toInt(),
    };
  }

  Map<String, dynamic> toMap() => {
        'farmId': farmId,
        'generatedAt': generatedAt.toIso8601String(),
        'totalDiseases': totalDiseases,
        'criticalCount': criticalCount,
        'averageConfidence': averageConfidence,
        'mostCommonDisease': mostCommonDisease,
        'averageYield': averageYield,
        'yieldTrend': yieldTrend,
        'yieldIncreasing': yieldIncreasing,
        'currentStage': currentStage,
        'estimatedHarvest': estimatedHarvest.toIso8601String(),
        'daysToHarvest': daysToHarvest,
      };

  @override
  String toString() =>
      'AnalyticsSummary($farmId, diseases: $totalDiseases, yield: ${averageYield.toStringAsFixed(0)}, stage: $currentStage)';
}

class TrendData {
  final DateTime date;
  final double value;
  final String label;

  const TrendData({
    required this.date,
    required this.value,
    required this.label,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'value': value,
        'label': label,
      };
}

class ChartDataPoint {
  final String label;
  final double value;
  final String? color;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'value': value,
        'color': color,
      };
}
