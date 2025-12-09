import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/ai_predictions/models/disease_prediction.dart';

void main() {
  group('DiseasePrediction', () {
    test('DiseasePrediction creation with all fields', () {
      final prediction = DiseasePrediction(
        diseaseName: 'Early Blight',
        confidence: 0.92,
        severity: 'High',
        treatments: ['Apply fungicide', 'Prune affected areas'],
        detectionTime: DateTime(2025, 12, 9, 14, 30),
        farmId: 'farm_123',
        photoPath: '/path/to/photo.jpg',
      );

      expect(prediction.diseaseName, 'Early Blight');
      expect(prediction.confidence, 0.92);
      expect(prediction.severity, 'High');
      expect(prediction.treatments.length, 2);
      expect(prediction.farmId, 'farm_123');
      expect(prediction.photoPath, '/path/to/photo.jpg');
    });

    test('DiseasePrediction severity classification - Critical', () {
      final prediction = DiseasePrediction(
        diseaseName: 'Leaf Spot',
        confidence: 0.95,
        severity: 'Critical',
        treatments: [],
        detectionTime: DateTime.now(),
      );

      expect(prediction.severity, 'Critical');
    });

    test('DiseasePrediction severity classification - High', () {
      final prediction = DiseasePrediction(
        diseaseName: 'Leaf Spot',
        confidence: 0.78,
        severity: 'High',
        treatments: [],
        detectionTime: DateTime.now(),
      );

      expect(prediction.severity, 'High');
    });

    test('DiseasePrediction severity classification - Medium', () {
      final prediction = DiseasePrediction(
        diseaseName: 'Leaf Spot',
        confidence: 0.62,
        severity: 'Medium',
        treatments: [],
        detectionTime: DateTime.now(),
      );

      expect(prediction.severity, 'Medium');
    });

    test('DiseasePrediction severity classification - Low', () {
      final prediction = DiseasePrediction(
        diseaseName: 'Leaf Spot',
        confidence: 0.45,
        severity: 'Low',
        treatments: [],
        detectionTime: DateTime.now(),
      );

      expect(prediction.severity, 'Low');
    });

    test('DiseasePrediction.fromInference creates correct severity', () {
      final inferenceResult = {
        'disease': 'Early Blight',
        'confidence': 0.88,
        'treatments': ['Fungicide spray', 'Remove leaves'],
      };

      final prediction = DiseasePrediction.fromInference(
        inferenceResult,
        photoPath: 'test.jpg',
        farmId: 'farm_001',
      );

      expect(prediction.diseaseName, 'Early Blight');
      expect(prediction.confidence, 0.88);
      expect(prediction.severity, 'High');
      expect(prediction.treatments.length, 2);
    });

    test('DiseasePrediction.toMap serialization', () {
      final prediction = DiseasePrediction(
        diseaseName: 'Powdery Mildew',
        confidence: 0.85,
        severity: 'High',
        treatments: ['Apply sulfur', 'Improve ventilation'],
        detectionTime: DateTime(2025, 12, 9, 14, 30),
        farmId: 'farm_456',
      );

      final map = prediction.toMap();

      expect(map['diseaseName'], 'Powdery Mildew');
      expect(map['confidence'], 0.85);
      expect(map['severity'], 'High');
      expect(map['treatments'], isA<String>());
      expect(map['farmId'], 'farm_456');
    });

    test('DiseasePrediction.fromMap deserialization', () {
      final map = {
        'diseaseName': 'Rust',
        'confidence': 0.92,
        'severity': 'Critical',
        'treatments': 'Copper fungicide,Improve drainage',
        'detectionTime': '2025-12-09 10:00:00.000',
        'farmId': 'farm_789',
        'photoPath': '/photo.jpg',
      };

      final prediction = DiseasePrediction.fromMap(map);

      expect(prediction.diseaseName, 'Rust');
      expect(prediction.confidence, 0.92);
      expect(prediction.severity, 'Critical');
      expect(prediction.treatments.length, 2);
      expect(prediction.farmId, 'farm_789');
    });

    test('DiseasePrediction.copyWith', () {
      final original = DiseasePrediction(
        diseaseName: 'Blight',
        confidence: 0.7,
        severity: 'Medium',
        treatments: ['Treatment 1'],
        detectionTime: DateTime.now(),
        farmId: 'farm_001',
      );

      final updated = original.copyWith(
        confidence: 0.95,
        severity: 'Critical',
      );

      expect(updated.diseaseName, 'Blight');
      expect(updated.confidence, 0.95);
      expect(updated.severity, 'Critical');
      expect(updated.treatments.length, 1);
      expect(updated.farmId, 'farm_001');
    });

    test('DiseasePrediction equality', () {
      final now = DateTime.now();

      final pred1 = DiseasePrediction(
        diseaseName: 'Disease',
        confidence: 0.8,
        severity: 'High',
        treatments: ['T1'],
        detectionTime: now,
        farmId: 'farm_1',
      );

      final pred2 = DiseasePrediction(
        diseaseName: 'Disease',
        confidence: 0.8,
        severity: 'High',
        treatments: ['T1'],
        detectionTime: now,
        farmId: 'farm_1',
      );

      expect(pred1, pred2);
    });

    test('DiseasePrediction toString does not crash', () {
      final prediction = DiseasePrediction(
        diseaseName: 'Test Disease',
        confidence: 0.75,
        severity: 'Medium',
        treatments: ['Treatment'],
        detectionTime: DateTime.now(),
      );

      final str = prediction.toString();
      expect(str, contains('DiseasePrediction'));
      expect(str, contains('Test Disease'));
    });

    test('DiseasePrediction with empty treatments', () {
      final prediction = DiseasePrediction(
        diseaseName: 'Minor Spot',
        confidence: 0.55,
        severity: 'Low',
        treatments: [],
        detectionTime: DateTime.now(),
      );

      expect(prediction.treatments, isEmpty);
      final map = prediction.toMap();
      expect(map['treatments'], isEmpty);
    });

    test('DiseasePrediction null farm fields', () {
      final prediction = DiseasePrediction(
        diseaseName: 'Disease',
        confidence: 0.8,
        severity: 'High',
        treatments: ['T1'],
        detectionTime: DateTime.now(),
        farmId: null,
        photoPath: null,
      );

      expect(prediction.farmId, isNull);
      expect(prediction.photoPath, isNull);
    });
  });
}
