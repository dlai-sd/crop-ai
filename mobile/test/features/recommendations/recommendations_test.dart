import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/recommendations/models/recommendation.dart';
import 'package:crop_ai/features/recommendations/data/recommendations_repository.dart';

void main() {
  group('TreatmentRecommendation', () {
    test('fromDisease creates recommendation from disease ID', () {
      final rec = TreatmentRecommendation.fromDisease('early_blight', 'Early Blight', 0.85);

      expect(rec.diseaseName, equals('Early Blight'));
      expect(rec.severity, equals(RecommendationSeverity.critical));
      expect(rec.treatmentName, isNotEmpty);
    });

    test('fromDisease sets critical severity for high confidence', () {
      final rec = TreatmentRecommendation.fromDisease('late_blight', 'Late Blight', 0.9);
      expect(rec.severity, equals(RecommendationSeverity.critical));
    });

    test('fromDisease sets high severity for medium-high confidence', () {
      final rec = TreatmentRecommendation.fromDisease('powdery_mildew', 'Powdery Mildew', 0.7);
      expect(rec.severity, equals(RecommendationSeverity.high));
    });

    test('fromDisease returns generic treatment for unknown disease', () {
      final rec = TreatmentRecommendation.fromDisease('unknown_disease', 'Unknown', 0.5);
      expect(rec.treatmentName, equals('Monitor & Isolate'));
    });

    test('toMap serializes all fields', () {
      final rec = TreatmentRecommendation(
        id: 'test_001',
        diseaseId: 'test_disease',
        diseaseName: 'Test Disease',
        treatmentName: 'Test Treatment',
        description: 'Test description',
        steps: ['Step 1', 'Step 2'],
        pesticide: 'Test Pesticide',
        dosage: 2.5,
        unit: 'kg',
        daysToReapply: 7,
        expectedEffectiveness: 0.85,
        cost: 1500,
        supplier: 'Test Supplier',
        severity: RecommendationSeverity.high,
        recommendedDate: DateTime(2025, 12, 9),
      );

      final map = rec.toMap();
      expect(map['id'], equals('test_001'));
      expect(map['treatmentName'], equals('Test Treatment'));
      expect(map['dosage'], equals(2.5));
    });
  });

  group('YieldOptimizationRecommendation', () {
    test('fromPrediction creates recommendation with low yield', () {
      final rec = YieldOptimizationRecommendation.fromPrediction(
        'farm_001',
        2500,
        0.8,
        'vegetative',
      );

      expect(rec.type, equals('irrigation'));
      expect(rec.expectedYieldIncrease, greaterThan(0));
      expect(rec.severity, equals(RecommendationSeverity.high));
    });

    test('fromPrediction creates recommendation with high yield', () {
      final rec = YieldOptimizationRecommendation.fromPrediction(
        'farm_001',
        4600,
        0.85,
        'flowering',
      );

      expect(rec.type, equals('fertilizer'));
      expect(rec.title, contains('Optimize'));
    });

    test('fromPrediction returns maintenance recommendation for normal yield', () {
      final rec = YieldOptimizationRecommendation.fromPrediction(
        'farm_001',
        3500,
        0.8,
        'growth',
      );

      expect(rec.severity, equals(RecommendationSeverity.info));
      expect(rec.expectedYieldIncrease, equals(0));
    });
  });

  group('RiskAlert', () {
    test('fromPredictions detects disease risk', () {
      final diseaseConfidences = {
        'early_blight': 0.85,
        'late_blight': 0.75,
      };

      final alert = RiskAlert.fromPredictions('farm_001', diseaseConfidences);

      expect(alert.riskType, equals('disease'));
      expect(alert.severity, equals(RecommendationSeverity.critical));
      expect(alert.description, contains('early_blight'));
    });

    test('fromPredictions returns low risk when diseases below threshold', () {
      final diseaseConfidences = {
        'early_blight': 0.3,
        'late_blight': 0.4,
      };

      final alert = RiskAlert.fromPredictions('farm_001', diseaseConfidences);

      expect(alert.riskScore, lessThan(0.5));
    });
  });

  group('RecommendationsRepository', () {
    late RecommendationsRepository repository;

    setUp(() {
      repository = RecommendationsRepository();
    });

    test('getTreatmentRecommendations returns sorted by severity', () async {
      final diseaseConfidences = {
        'early_blight': 0.9,
        'powdery_mildew': 0.5,
      };

      final recs = await repository.getTreatmentRecommendations('farm_001', diseaseConfidences);

      expect(recs.isNotEmpty, isTrue);
      expect(recs[0].severity, equals(RecommendationSeverity.critical));
    });

    test('getTreatmentRecommendations filters low confidence diseases', () async {
      final diseaseConfidences = {
        'early_blight': 0.2, // Below 30% threshold
      };

      final recs = await repository.getTreatmentRecommendations('farm_001', diseaseConfidences);

      expect(recs, isEmpty);
    });

    test('getYieldRecommendations returns multiple recommendations', () async {
      final recs = await repository.getYieldRecommendations(
        'farm_001',
        2800,
        0.8,
        'vegetative',
      );

      expect(recs.length, greaterThanOrEqualTo(1));
    });

    test('getRiskAlerts returns alerts for high disease risk', () async {
      final diseaseConfidences = {
        'early_blight': 0.85,
      };

      final alerts = await repository.getRiskAlerts(
        'farm_001',
        diseaseConfidences,
        3500,
        'normal',
      );

      expect(alerts.isNotEmpty, isTrue);
    });

    test('getRiskAlerts returns alerts for low yield', () async {
      final diseaseConfidences = {};

      final alerts = await repository.getRiskAlerts(
        'farm_001',
        diseaseConfidences,
        2000, // Below 2500 threshold
        'normal',
      );

      expect(alerts.any((a) => a.riskType == 'yield'), isTrue);
    });

    test('getRiskAlerts returns weather alerts', () async {
      final diseaseConfidences = {};

      final alerts = await repository.getRiskAlerts(
        'farm_001',
        diseaseConfidences,
        3500,
        'heavy_rain_forecast',
      );

      expect(alerts.any((a) => a.riskType == 'weather'), isTrue);
    });

    test('getAllRecommendations returns combined results', () async {
      final diseaseConfidences = {'early_blight': 0.8};

      final result = await repository.getAllRecommendations(
        'farm_001',
        diseaseConfidences,
        3000,
        0.8,
        'growth',
        'normal',
      );

      expect(result.containsKey('treatments'), isTrue);
      expect(result.containsKey('yieldOptimizations'), isTrue);
      expect(result.containsKey('riskAlerts'), isTrue);
    });
  });
}
