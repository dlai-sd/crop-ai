enum GrowthStage {
  seedling,    // 0-2 weeks
  vegetative,  // 3-8 weeks
  flowering,   // 9-12 weeks
  fruitGrain,  // 13-18 weeks
  mature,      // 19-24 weeks
  harvestReady // 25+ weeks
}

extension GrowthStageExtension on GrowthStage {
  String get displayName {
    switch (this) {
      case GrowthStage.seedling:
        return 'Seedling';
      case GrowthStage.vegetative:
        return 'Vegetative';
      case GrowthStage.flowering:
        return 'Flowering';
      case GrowthStage.fruitGrain:
        return 'Fruit/Grain Formation';
      case GrowthStage.mature:
        return 'Mature';
      case GrowthStage.harvestReady:
        return 'Harvest Ready';
    }
  }

  String get emoji {
    switch (this) {
      case GrowthStage.seedling:
        return '🌱';
      case GrowthStage.vegetative:
        return '🌿';
      case GrowthStage.flowering:
        return '🌼';
      case GrowthStage.fruitGrain:
        return '🌾';
      case GrowthStage.mature:
        return '🌽';
      case GrowthStage.harvestReady:
        return '🚜';
    }
  }

  int get weekStart {
    switch (this) {
      case GrowthStage.seedling:
        return 0;
      case GrowthStage.vegetative:
        return 3;
      case GrowthStage.flowering:
        return 9;
      case GrowthStage.fruitGrain:
        return 13;
      case GrowthStage.mature:
        return 19;
      case GrowthStage.harvestReady:
        return 25;
    }
  }

  int get weekEnd {
    switch (this) {
      case GrowthStage.seedling:
        return 2;
      case GrowthStage.vegetative:
        return 8;
      case GrowthStage.flowering:
        return 12;
      case GrowthStage.fruitGrain:
        return 18;
      case GrowthStage.mature:
        return 24;
      case GrowthStage.harvestReady:
        return 999; // Open-ended
    }
  }
}

class GrowthStagePrediction {
  final GrowthStage currentStage;
  final double daysInStage;
  final double daysToNextStage;
  final List<String> recommendations;
  final Map<String, dynamic> stageMetrics;
  final DateTime predictionTime;
  final String? farmId;
  final double confidence;

  GrowthStagePrediction({
    required this.currentStage,
    required this.daysInStage,
    required this.daysToNextStage,
    required this.recommendations,
    required this.stageMetrics,
    required this.predictionTime,
    required this.confidence,
    this.farmId,
  });

  // Factory for creating from model inference
  factory GrowthStagePrediction.fromInference({
    required GrowthStage stage,
    required double daysSincePlanting,
    required double confidence,
    required List<String> recommendations,
    required Map<String, dynamic> metrics,
    String? farmId,
  }) {
    // Calculate days in current stage
    final daysInStage = daysSincePlanting - (stage.weekStart * 7);
    
    // Calculate days to next stage
    final nextStageStart = _getNextStageStart(stage);
    final daysSinceStart = daysSincePlanting;
    final daysToNext = (nextStageStart * 7) - daysSinceStart;

    return GrowthStagePrediction(
      currentStage: stage,
      daysInStage: daysInStage.clamp(0, double.infinity),
      daysToNextStage: daysToNext.clamp(0, double.infinity),
      recommendations: recommendations,
      stageMetrics: metrics,
      predictionTime: DateTime.now(),
      confidence: confidence,
      farmId: farmId,
    );
  }

  static int _getNextStageStart(GrowthStage stage) {
    switch (stage) {
      case GrowthStage.seedling:
        return 3;
      case GrowthStage.vegetative:
        return 9;
      case GrowthStage.flowering:
        return 13;
      case GrowthStage.fruitGrain:
        return 19;
      case GrowthStage.mature:
        return 25;
      case GrowthStage.harvestReady:
        return 999;
    }
  }

  // Get stage-specific recommendations
  List<String> getRecommendations() {
    final baseRecs = <String>[
      _getStageSpecificTip(),
      ...recommendations,
    ];
    return baseRecs.take(5).toList(); // Top 5 recommendations
  }

  String _getStageSpecificTip() {
    switch (currentStage) {
      case GrowthStage.seedling:
        return 'Ensure consistent moisture and protect from pests';
      case GrowthStage.vegetative:
        return 'Apply nitrogen fertilizer for vegetative growth';
      case GrowthStage.flowering:
        return 'Maintain moisture; apply phosphorus and potassium';
      case GrowthStage.fruitGrain:
        return 'Monitor for pests and diseases; ensure adequate water';
      case GrowthStage.mature:
        return 'Reduce water; monitor for maturity indicators';
      case GrowthStage.harvestReady:
        return 'Prepare harvesting equipment; monitor weather';
    }
  }

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'currentStage': currentStage.toString(),
      'daysInStage': daysInStage,
      'daysToNextStage': daysToNextStage,
      'recommendations': recommendations,
      'stageMetrics': stageMetrics,
      'predictionTime': predictionTime.toIso8601String(),
      'confidence': confidence,
      'farmId': farmId,
    };
  }

  factory GrowthStagePrediction.fromMap(Map<String, dynamic> map) {
    final stageStr = map['currentStage'] as String;
    final stage = GrowthStage.values.firstWhere(
      (e) => e.toString() == stageStr,
      orElse: () => GrowthStage.vegetative,
    );
    
    return GrowthStagePrediction(
      currentStage: stage,
      daysInStage: (map['daysInStage'] as num).toDouble(),
      daysToNextStage: (map['daysToNextStage'] as num).toDouble(),
      recommendations: List<String>.from(map['recommendations'] as List),
      stageMetrics: map['stageMetrics'] as Map<String, dynamic>,
      predictionTime: DateTime.parse(map['predictionTime'] as String),
      confidence: (map['confidence'] as num).toDouble(),
      farmId: map['farmId'] as String?,
    );
  }

  GrowthStagePrediction copyWith({
    GrowthStage? currentStage,
    double? daysInStage,
    double? daysToNextStage,
    List<String>? recommendations,
    Map<String, dynamic>? stageMetrics,
    DateTime? predictionTime,
    String? farmId,
    double? confidence,
  }) {
    return GrowthStagePrediction(
      currentStage: currentStage ?? this.currentStage,
      daysInStage: daysInStage ?? this.daysInStage,
      daysToNextStage: daysToNextStage ?? this.daysToNextStage,
      recommendations: recommendations ?? this.recommendations,
      stageMetrics: stageMetrics ?? this.stageMetrics,
      predictionTime: predictionTime ?? this.predictionTime,
      confidence: confidence ?? this.confidence,
      farmId: farmId ?? this.farmId,
    );
  }

  @override
  String toString() =>
      'GrowthStagePrediction(stage: ${currentStage.displayName}, days in stage: ${daysInStage.toStringAsFixed(1)}, next in: ${daysToNextStage.toStringAsFixed(1)} days)';
}
