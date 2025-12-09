import 'package:crop_ai/features/predictions/models/prediction_result.dart';

/// Recommendation severity level
enum RecommendationSeverity { critical, high, medium, low, info }

/// Treatment recommendation for disease management
class TreatmentRecommendation {
  final String id;
  final String diseaseId;
  final String diseaseName;
  final String treatmentName;
  final String description;
  final List<String> steps; // Step-by-step application instructions
  final String pesticide; // Recommended pesticide/chemical
  final double dosage; // kg/l per hectare
  final String unit; // kg or l
  final int daysToReapply;
  final double expectedEffectiveness; // 0-1 effectiveness rate
  final double cost; // Cost per hectare
  final String supplier; // Local supplier recommendation
  final RecommendationSeverity severity;
  final DateTime recommendedDate;
  final bool isOrganic;

  TreatmentRecommendation({
    required this.id,
    required this.diseaseId,
    required this.diseaseName,
    required this.treatmentName,
    required this.description,
    required this.steps,
    required this.pesticide,
    required this.dosage,
    required this.unit,
    required this.daysToReapply,
    required this.expectedEffectiveness,
    required this.cost,
    required this.supplier,
    required this.severity,
    required this.recommendedDate,
    this.isOrganic = false,
  });

  factory TreatmentRecommendation.fromDisease(
    String diseaseId,
    String diseaseName,
    double confidence,
  ) {
    // Treatment rules engine - maps diseases to treatments
    final treatments = _diseaseToTreatmentMap[diseaseId] ?? [];
    if (treatments.isEmpty) {
      return TreatmentRecommendation(
        id: '$diseaseId-generic',
        diseaseId: diseaseId,
        diseaseName: diseaseName,
        treatmentName: 'Monitor & Isolate',
        description: 'No specific treatment mapped. Monitor crop closely.',
        steps: ['Scout affected plants daily', 'Remove infected leaves', 'Monitor spread'],
        pesticide: 'N/A',
        dosage: 0,
        unit: 'N/A',
        daysToReapply: 7,
        expectedEffectiveness: 0.3,
        cost: 0,
        supplier: 'N/A',
        severity: RecommendationSeverity.info,
        recommendedDate: DateTime.now(),
      );
    }

    final treatment = treatments[0];
    final severity = confidence > 0.8
        ? RecommendationSeverity.critical
        : confidence > 0.6
            ? RecommendationSeverity.high
            : RecommendationSeverity.medium;

    return TreatmentRecommendation(
      id: '$diseaseId-${treatment['name']}',
      diseaseId: diseaseId,
      diseaseName: diseaseName,
      treatmentName: treatment['name'] as String,
      description: treatment['description'] as String,
      steps: List<String>.from(treatment['steps'] as List),
      pesticide: treatment['pesticide'] as String,
      dosage: treatment['dosage'] as double,
      unit: treatment['unit'] as String,
      daysToReapply: treatment['daysToReapply'] as int,
      expectedEffectiveness: treatment['effectiveness'] as double,
      cost: treatment['cost'] as double,
      supplier: treatment['supplier'] as String,
      severity: severity,
      recommendedDate: DateTime.now(),
      isOrganic: treatment['isOrganic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'diseaseId': diseaseId,
        'diseaseName': diseaseName,
        'treatmentName': treatmentName,
        'description': description,
        'steps': steps,
        'pesticide': pesticide,
        'dosage': dosage,
        'unit': unit,
        'daysToReapply': daysToReapply,
        'expectedEffectiveness': expectedEffectiveness,
        'cost': cost,
        'supplier': supplier,
        'severity': severity.toString(),
        'recommendedDate': recommendedDate.toIso8601String(),
        'isOrganic': isOrganic,
      };
}

/// Yield optimization recommendation
class YieldOptimizationRecommendation {
  final String id;
  final String type; // irrigation, fertilizer, planting_time, variety
  final String title;
  final String description;
  final String actionItem;
  final double expectedYieldIncrease; // kg/ha
  final double confidence;
  final double cost;
  final String timingWindow; // e.g., "Next 2 weeks", "Before monsoon"
  final RecommendationSeverity severity;
  final DateTime recommendedDate;

  YieldOptimizationRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.actionItem,
    required this.expectedYieldIncrease,
    required this.confidence,
    required this.cost,
    required this.timingWindow,
    required this.severity,
    required this.recommendedDate,
  });

  factory YieldOptimizationRecommendation.fromPrediction(
    String farmId,
    double predictedYield,
    double confidence,
    String growthStage,
  ) {
    // Yield optimization rules
    if (predictedYield < 3000) {
      return YieldOptimizationRecommendation(
        id: '$farmId-yield-low',
        type: 'irrigation',
        title: 'Increase Irrigation',
        description: 'Predicted yield is below average. Increase irrigation frequency.',
        actionItem: 'Increase watering to 2x daily during growth stage',
        expectedYieldIncrease: 500,
        confidence: 0.75,
        cost: 2000,
        timingWindow: 'Immediately',
        severity: RecommendationSeverity.high,
        recommendedDate: DateTime.now(),
      );
    }

    if (predictedYield > 4500 && confidence > 0.8) {
      return YieldOptimizationRecommendation(
        id: '$farmId-yield-optimize',
        type: 'fertilizer',
        title: 'Optimize Nutrient Management',
        description: 'High yield potential detected. Optimize fertilizer timing.',
        actionItem: 'Apply secondary nutrients during flowering stage',
        expectedYieldIncrease: 300,
        confidence: 0.82,
        cost: 1500,
        timingWindow: 'Next 3-5 days',
        severity: RecommendationSeverity.medium,
        recommendedDate: DateTime.now(),
      );
    }

    return YieldOptimizationRecommendation(
      id: '$farmId-yield-maintain',
      type: 'monitoring',
      title: 'Continue Current Management',
      description: 'Current crop management is optimal. Maintain practices.',
      actionItem: 'Monitor soil moisture and apply recommended irrigation',
      expectedYieldIncrease: 0,
      confidence: confidence,
      cost: 0,
      timingWindow: 'Ongoing',
      severity: RecommendationSeverity.info,
      recommendedDate: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'actionItem': actionItem,
        'expectedYieldIncrease': expectedYieldIncrease,
        'confidence': confidence,
        'cost': cost,
        'timingWindow': timingWindow,
        'severity': severity.toString(),
        'recommendedDate': recommendedDate.toIso8601String(),
      };
}

/// Risk alert for potential crop issues
class RiskAlert {
  final String id;
  final String riskType; // disease, pest, weather, soil, water
  final String title;
  final String description;
  final String mitigation;
  final double riskScore; // 0-1
  final RecommendationSeverity severity;
  final DateTime detectedDate;
  final DateTime expectedImpactDate;

  RiskAlert({
    required this.id,
    required this.riskType,
    required this.title,
    required this.description,
    required this.mitigation,
    required this.riskScore,
    required this.severity,
    required this.detectedDate,
    required this.expectedImpactDate,
  });

  factory RiskAlert.fromPredictions(
    String farmId,
    Map<String, double> diseaseConfidences,
  ) {
    // Risk detection logic
    final highRiskDiseases = diseaseConfidences.entries
        .where((e) => e.value > 0.7)
        .map((e) => '${e.key} (${(e.value * 100).toStringAsFixed(0)}%)')
        .toList();

    if (highRiskDiseases.isNotEmpty) {
      return RiskAlert(
        id: '$farmId-disease-risk',
        riskType: 'disease',
        title: 'High Disease Risk Detected',
        description: 'Multiple diseases at high confidence: ${highRiskDiseases.join(", ")}',
        mitigation: 'Apply preventive fungicide. Scout fields daily. Improve air circulation.',
        riskScore: 0.8,
        severity: RecommendationSeverity.critical,
        detectedDate: DateTime.now(),
        expectedImpactDate: DateTime.now().add(Duration(days: 3)),
      );
    }

    return RiskAlert(
      id: '$farmId-low-risk',
      riskType: 'general',
      title: 'Low Overall Risk',
      description: 'Current risk profile indicates stable growing conditions.',
      mitigation: 'Continue standard management practices. Monitor weather.',
      riskScore: 0.2,
      severity: RecommendationSeverity.info,
      detectedDate: DateTime.now(),
      expectedImpactDate: DateTime.now().add(Duration(days: 14)),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'riskType': riskType,
        'title': title,
        'description': description,
        'mitigation': mitigation,
        'riskScore': riskScore,
        'severity': severity.toString(),
        'detectedDate': detectedDate.toIso8601String(),
        'expectedImpactDate': expectedImpactDate.toIso8601String(),
      };
}

/// Disease-to-treatment mapping database
const Map<String, List<Map<String, dynamic>>> _diseaseToTreatmentMap = {
  'early_blight': [
    {
      'name': 'Fungicide Spray - Mancozeb',
      'description': 'Apply mancozeb-based fungicide for early blight control',
      'steps': [
        'Mix 2.5 kg mancozeb per 1000L water',
        'Spray in early morning or late evening',
        'Cover all leaf surfaces thoroughly',
        'Reapply every 7-10 days',
        'Increase frequency during wet season'
      ],
      'pesticide': 'Mancozeb 75% WP',
      'dosage': 2.5,
      'unit': 'kg',
      'daysToReapply': 7,
      'effectiveness': 0.85,
      'cost': 1500,
      'supplier': 'Local Agricultural Supplier',
      'isOrganic': false,
    }
  ],
  'late_blight': [
    {
      'name': 'Copper Fungicide - Bordeaux Mixture',
      'description': 'Traditional Bordeaux mixture for late blight prevention',
      'steps': [
        'Prepare Bordeaux mixture (1% concentration)',
        'Apply every 10-14 days during growing season',
        'Spray all plant parts including stems',
        'Remove infected leaves after spraying',
        'Ensure good field drainage'
      ],
      'pesticide': 'Copper Sulfate + Lime',
      'dosage': 1.0,
      'unit': 'l',
      'daysToReapply': 10,
      'effectiveness': 0.80,
      'cost': 800,
      'supplier': 'Organic Certified Supplier',
      'isOrganic': true,
    }
  ],
  'powdery_mildew': [
    {
      'name': 'Sulfur Powder - Elemental Sulfur',
      'description': 'Apply sulfur powder for powdery mildew management',
      'steps': [
        'Use dusting sulfur (400 mesh)',
        'Apply 5-10 kg per hectare',
        'Dust early in morning or late evening',
        'Avoid application above 27°C',
        'Reapply every 7 days if needed'
      ],
      'pesticide': 'Sulfur 80% WP',
      'dosage': 8.0,
      'unit': 'kg',
      'daysToReapply': 7,
      'effectiveness': 0.75,
      'cost': 600,
      'supplier': 'Local Agro Store',
      'isOrganic': true,
    }
  ],
  'bacterial_spot': [
    {
      'name': 'Copper Fungicide - Fixed Copper',
      'description': 'Fixed copper fungicide for bacterial spot control',
      'steps': [
        'Mix 2.5 kg fixed copper per 1000L water',
        'Apply at first sign of symptoms',
        'Repeat every 7-10 days during wet season',
        'Remove heavily infected leaves',
        'Improve air circulation in canopy'
      ],
      'pesticide': 'Fixed Copper 50% WP',
      'dosage': 2.5,
      'unit': 'kg',
      'daysToReapply': 10,
      'effectiveness': 0.70,
      'cost': 1200,
      'supplier': 'Agricultural Cooperative',
      'isOrganic': true,
    }
  ],
  'septoria_leaf_spot': [
    {
      'name': 'Carbendazim + Mancozeb',
      'description': 'Combined fungicide for septoria leaf spot management',
      'steps': [
        'Mix 1.2 kg Carbendazim + 2.5 kg Mancozeb per 1000L',
        'Spray every 10 days starting from boot stage',
        'Focus on lower leaves and older foliage',
        'Ensure complete coverage',
        'Stop spraying 2 weeks before harvest'
      ],
      'pesticide': 'Carbendazim + Mancozeb',
      'dosage': 3.7,
      'unit': 'kg',
      'daysToReapply': 10,
      'effectiveness': 0.82,
      'cost': 2000,
      'supplier': 'Premium Agro Supplies',
      'isOrganic': false,
    }
  ],
};
