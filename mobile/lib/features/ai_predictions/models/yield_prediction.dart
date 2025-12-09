class YieldPrediction {
  final double estimatedYield; // kg/hectare
  final double lowerBound; // 95% confidence interval lower
  final double upperBound; // 95% confidence interval upper
  final double confidence;
  final List<String> riskFactors; // What could reduce yield
  final List<String> opportunities; // What could increase yield
  final DateTime predictionTime;
  final String? farmId;

  YieldPrediction({
    required this.estimatedYield,
    required this.lowerBound,
    required this.upperBound,
    required this.confidence,
    required this.riskFactors,
    required this.opportunities,
    required this.predictionTime,
    this.farmId,
  });

  // Factory for creating from model inference
  factory YieldPrediction.fromInference({
    required double estimatedYield,
    required double stdDev,
    required List<String> riskFactors,
    required List<String> opportunities,
    String? farmId,
  }) {
    // Calculate 95% confidence intervals (±1.96 * stdDev)
    final margin = 1.96 * stdDev;
    return YieldPrediction(
      estimatedYield: estimatedYield,
      lowerBound: (estimatedYield - margin).clamp(0, double.infinity),
      upperBound: estimatedYield + margin,
      confidence: _calculateConfidence(stdDev, estimatedYield),
      riskFactors: riskFactors,
      opportunities: opportunities,
      predictionTime: DateTime.now(),
      farmId: farmId,
    );
  }

  static double _calculateConfidence(double stdDev, double mean) {
    // Higher confidence when stdDev is lower relative to mean
    if (mean == 0) return 0.5;
    final cv = stdDev / mean; // Coefficient of variation
    return (1 - (cv / 2)).clamp(0, 1);
  }

  // Get confidence interval width
  double get intervalWidth => upperBound - lowerBound;

  // Check if prediction is reliable (narrow confidence interval)
  bool get isReliable => confidence >= 0.75;

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'estimatedYield': estimatedYield,
      'lowerBound': lowerBound,
      'upperBound': upperBound,
      'confidence': confidence,
      'riskFactors': riskFactors,
      'opportunities': opportunities,
      'predictionTime': predictionTime.toIso8601String(),
      'farmId': farmId,
    };
  }

  factory YieldPrediction.fromMap(Map<String, dynamic> map) {
    return YieldPrediction(
      estimatedYield: (map['estimatedYield'] as num).toDouble(),
      lowerBound: (map['lowerBound'] as num).toDouble(),
      upperBound: (map['upperBound'] as num).toDouble(),
      confidence: (map['confidence'] as num).toDouble(),
      riskFactors: List<String>.from(map['riskFactors'] as List),
      opportunities: List<String>.from(map['opportunities'] as List),
      predictionTime: DateTime.parse(map['predictionTime'] as String),
      farmId: map['farmId'] as String?,
    );
  }

  YieldPrediction copyWith({
    double? estimatedYield,
    double? lowerBound,
    double? upperBound,
    double? confidence,
    List<String>? riskFactors,
    List<String>? opportunities,
    DateTime? predictionTime,
    String? farmId,
  }) {
    return YieldPrediction(
      estimatedYield: estimatedYield ?? this.estimatedYield,
      lowerBound: lowerBound ?? this.lowerBound,
      upperBound: upperBound ?? this.upperBound,
      confidence: confidence ?? this.confidence,
      riskFactors: riskFactors ?? this.riskFactors,
      opportunities: opportunities ?? this.opportunities,
      predictionTime: predictionTime ?? this.predictionTime,
      farmId: farmId ?? this.farmId,
    );
  }

  @override
  String toString() =>
      'YieldPrediction(yield: ${estimatedYield.toStringAsFixed(0)} kg/ha, CI: [${lowerBound.toStringAsFixed(0)}-${upperBound.toStringAsFixed(0)}], confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}
