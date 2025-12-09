import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiseasePrediction {
  final String diseaseName;
  final double confidence;
  final String severity; // Low, Medium, High, Critical
  final List<String> treatments;
  final DateTime detectionTime;
  final String? farmId;
  final String? photoPath;

  DiseasePrediction({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.treatments,
    required this.detectionTime,
    this.farmId,
    this.photoPath,
  });

  // Severity classification based on confidence
  factory DiseasePrediction.fromInference({
    required String diseaseName,
    required double confidence,
    required List<String> treatments,
    String? farmId,
    String? photoPath,
  }) {
    String severity = _classifySeverity(confidence);
    return DiseasePrediction(
      diseaseName: diseaseName,
      confidence: confidence,
      severity: severity,
      treatments: treatments,
      detectionTime: DateTime.now(),
      farmId: farmId,
      photoPath: photoPath,
    );
  }

  static String _classifySeverity(double confidence) {
    if (confidence >= 0.9) return 'Critical';
    if (confidence >= 0.75) return 'High';
    if (confidence >= 0.6) return 'Medium';
    return 'Low';
  }

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'diseaseName': diseaseName,
      'confidence': confidence,
      'severity': severity,
      'treatments': treatments,
      'detectionTime': detectionTime.toIso8601String(),
      'farmId': farmId,
      'photoPath': photoPath,
    };
  }

  factory DiseasePrediction.fromMap(Map<String, dynamic> map) {
    return DiseasePrediction(
      diseaseName: map['diseaseName'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      severity: map['severity'] as String,
      treatments: List<String>.from(map['treatments'] as List),
      detectionTime: DateTime.parse(map['detectionTime'] as String),
      farmId: map['farmId'] as String?,
      photoPath: map['photoPath'] as String?,
    );
  }

  DiseasePrediction copyWith({
    String? diseaseName,
    double? confidence,
    String? severity,
    List<String>? treatments,
    DateTime? detectionTime,
    String? farmId,
    String? photoPath,
  }) {
    return DiseasePrediction(
      diseaseName: diseaseName ?? this.diseaseName,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      treatments: treatments ?? this.treatments,
      detectionTime: detectionTime ?? this.detectionTime,
      farmId: farmId ?? this.farmId,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  @override
  String toString() =>
      'DiseasePrediction(disease: $diseaseName, confidence: ${(confidence * 100).toStringAsFixed(1)}%, severity: $severity)';
}
