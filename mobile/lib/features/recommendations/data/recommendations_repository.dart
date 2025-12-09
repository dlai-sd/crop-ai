import 'package:crop_ai/features/recommendations/models/recommendation.dart';
import 'package:crop_ai/features/predictions/models/prediction_result.dart';

/// Repository for generating crop recommendations
class RecommendationsRepository {
  /// Generate treatment recommendations for detected diseases
  Future<List<TreatmentRecommendation>> getTreatmentRecommendations(
    String farmId,
    Map<String, double> diseaseConfidences,
  ) async {
    // Simulate API/DB fetch
    await Future.delayed(Duration(milliseconds: 200));

    final recommendations = <TreatmentRecommendation>[];

    diseaseConfidences.forEach((diseaseId, confidence) {
      if (confidence > 0.3) {
        // Only recommend if confidence > 30%
        final recommendation = TreatmentRecommendation.fromDisease(
          diseaseId,
          diseaseId.replaceAll('_', ' '),
          confidence,
        );
        recommendations.add(recommendation);
      }
    });

    // Sort by severity
    recommendations.sort((a, b) {
      final severityOrder = {
        RecommendationSeverity.critical: 0,
        RecommendationSeverity.high: 1,
        RecommendationSeverity.medium: 2,
        RecommendationSeverity.low: 3,
        RecommendationSeverity.info: 4,
      };
      return (severityOrder[a.severity] ?? 4)
          .compareTo(severityOrder[b.severity] ?? 4);
    });

    return recommendations;
  }

  /// Generate yield optimization recommendations
  Future<List<YieldOptimizationRecommendation>> getYieldRecommendations(
    String farmId,
    double predictedYield,
    double yieldConfidence,
    String growthStage,
  ) async {
    // Simulate API/DB fetch
    await Future.delayed(Duration(milliseconds: 150));

    final recommendations = <YieldOptimizationRecommendation>[];

    // Primary yield recommendation
    final primary = YieldOptimizationRecommendation.fromPrediction(
      farmId,
      predictedYield,
      yieldConfidence,
      growthStage,
    );
    recommendations.add(primary);

    // Add seasonal secondary recommendations
    if (growthStage == 'vegetative') {
      recommendations.add(
        YieldOptimizationRecommendation(
          id: '$farmId-yield-veg',
          type: 'fertilizer',
          title: 'Boost Nitrogen Application',
          description: 'During vegetative stage, increase nitrogen for vigorous growth.',
          actionItem: 'Apply 50 kg N per hectare this week',
          expectedYieldIncrease: 400,
          confidence: 0.78,
          cost: 2500,
          timingWindow: 'This week',
          severity: RecommendationSeverity.medium,
          recommendedDate: DateTime.now(),
        ),
      );
    } else if (growthStage == 'flowering') {
      recommendations.add(
        YieldOptimizationRecommendation(
          id: '$farmId-yield-flower',
          type: 'fertilizer',
          title: 'Switch to Phosphorus-Rich Fertilizer',
          description: 'During flowering, phosphorus supports flower and fruit development.',
          actionItem: 'Apply DAP or SSP @ 50 kg per hectare',
          expectedYieldIncrease: 350,
          confidence: 0.82,
          cost: 2000,
          timingWindow: 'Next 2-3 days',
          severity: RecommendationSeverity.high,
          recommendedDate: DateTime.now(),
        ),
      );
    }

    return recommendations;
  }

  /// Generate risk alerts based on current conditions
  Future<List<RiskAlert>> getRiskAlerts(
    String farmId,
    Map<String, double> diseaseConfidences,
    double predictedYield,
    String weatherPattern,
  ) async {
    // Simulate API/DB fetch
    await Future.delayed(Duration(milliseconds: 180));

    final alerts = <RiskAlert>[];

    // Disease risk
    if (diseaseConfidences.values.any((c) => c > 0.7)) {
      alerts.add(RiskAlert.fromPredictions(farmId, diseaseConfidences));
    }

    // Yield risk
    if (predictedYield < 2500) {
      alerts.add(
        RiskAlert(
          id: '$farmId-yield-risk',
          riskType: 'yield',
          title: 'Low Yield Forecast',
          description: 'Predicted yield is below 2500 kg/ha. Investigate causes.',
          mitigation: 'Check soil nutrients, irrigation, and weed management.',
          riskScore: 0.75,
          severity: RecommendationSeverity.high,
          detectedDate: DateTime.now(),
          expectedImpactDate: DateTime.now().add(Duration(days: 10)),
        ),
      );
    }

    // Weather risk
    if (weatherPattern == 'heavy_rain_forecast') {
      alerts.add(
        RiskAlert(
          id: '$farmId-weather-risk',
          riskType: 'weather',
          title: 'Heavy Rain Forecast - Disease Risk',
          description: 'Heavy rainfall expected in 3-5 days may increase disease pressure.',
          mitigation: 'Apply preventive fungicide before rain. Ensure good drainage.',
          riskScore: 0.6,
          severity: RecommendationSeverity.high,
          detectedDate: DateTime.now(),
          expectedImpactDate: DateTime.now().add(Duration(days: 4)),
        ),
      );
    }

    // Sort by severity
    alerts.sort((a, b) {
      final severityOrder = {
        RecommendationSeverity.critical: 0,
        RecommendationSeverity.high: 1,
        RecommendationSeverity.medium: 2,
        RecommendationSeverity.low: 3,
        RecommendationSeverity.info: 4,
      };
      return (severityOrder[a.severity] ?? 4)
          .compareTo(severityOrder[b.severity] ?? 4);
    });

    return alerts;
  }

  /// Get treatment details including step-by-step application guide
  Future<TreatmentRecommendation> getTreatmentDetails(String treatmentId) async {
    await Future.delayed(Duration(milliseconds: 100));

    // This would normally fetch from database or API
    // For now returning a sample - in real implementation would query by ID
    return TreatmentRecommendation(
      id: treatmentId,
      diseaseId: 'sample_disease',
      diseaseName: 'Sample Disease',
      treatmentName: 'Sample Treatment',
      description: 'Sample treatment description',
      steps: ['Step 1', 'Step 2', 'Step 3'],
      pesticide: 'Sample Pesticide',
      dosage: 2.5,
      unit: 'kg',
      daysToReapply: 7,
      expectedEffectiveness: 0.85,
      cost: 1500,
      supplier: 'Local Supplier',
      severity: RecommendationSeverity.high,
      recommendedDate: DateTime.now(),
    );
  }

  /// Get all active recommendations for a farm
  Future<Map<String, dynamic>> getAllRecommendations(
    String farmId,
    Map<String, double> diseaseConfidences,
    double predictedYield,
    double yieldConfidence,
    String growthStage,
    String weatherPattern,
  ) async {
    final treatments = await getTreatmentRecommendations(farmId, diseaseConfidences);
    final yieldOpts = await getYieldRecommendations(
      farmId,
      predictedYield,
      yieldConfidence,
      growthStage,
    );
    final risks = await getRiskAlerts(farmId, diseaseConfidences, predictedYield, weatherPattern);

    return {
      'treatments': treatments,
      'yieldOptimizations': yieldOpts,
      'riskAlerts': risks,
      'generatedAt': DateTime.now(),
    };
  }
}
