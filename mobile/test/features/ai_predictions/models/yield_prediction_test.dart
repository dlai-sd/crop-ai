import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/ai_predictions/models/yield_prediction.dart';

void main() {
  group('YieldPrediction', () {
    test('YieldPrediction creation with all fields', () {
      final prediction = YieldPrediction(
        estimatedYield: 3500.0,
        lowerBound: 3200.0,
        upperBound: 3800.0,
        confidence: 0.85,
        riskFactors: ['Low rainfall', 'High pest pressure'],
        opportunities: ['Improved irrigation', 'Better fertilizer timing'],
      );

      expect(prediction.estimatedYield, 3500.0);
      expect(prediction.lowerBound, 3200.0);
      expect(prediction.upperBound, 3800.0);
      expect(prediction.confidence, 0.85);
      expect(prediction.riskFactors.length, 2);
      expect(prediction.opportunities.length, 2);
    });

    test('YieldPrediction.isReliable returns true for high confidence', () {
      final prediction = YieldPrediction(
        estimatedYield: 3500.0,
        lowerBound: 3300.0,
        upperBound: 3700.0,
        confidence: 0.85,
        riskFactors: [],
        opportunities: [],
      );

      expect(prediction.isReliable, true);
    });

    test('YieldPrediction.isReliable returns false for low confidence', () {
      final prediction = YieldPrediction(
        estimatedYield: 3500.0,
        lowerBound: 2800.0,
        upperBound: 4200.0,
        confidence: 0.65,
        riskFactors: [],
        opportunities: [],
      );

      expect(prediction.isReliable, false);
    });

    test('YieldPrediction.intervalWidth calculation', () {
      final prediction = YieldPrediction(
        estimatedYield: 3500.0,
        lowerBound: 3000.0,
        upperBound: 4000.0,
        confidence: 0.8,
        riskFactors: [],
        opportunities: [],
      );

      expect(prediction.intervalWidth, 1000.0);
    });

    test('YieldPrediction.fromInference calculates confidence interval', () {
      final inferenceResult = {
        'yield': 3500.0,
        'std_dev': 100.0,
        'risk_factors': ['Drought risk'],
        'opportunities': ['Better irrigation'],
      };

      final prediction = YieldPrediction.fromInference(inferenceResult);

      expect(prediction.estimatedYield, 3500.0);
      expect(prediction.lowerBound, lessThan(3500.0));
      expect(prediction.upperBound, greaterThan(3500.0));
      // 95% CI: estimated ± 1.96 * stdDev
      expect(prediction.lowerBound, closeTo(3500.0 - 196.0, 1.0));
      expect(prediction.upperBound, closeTo(3500.0 + 196.0, 1.0));
    });

    test('YieldPrediction.fromInference confidence calculation', () {
      final inferenceResult = {
        'yield': 3500.0,
        'std_dev': 100.0,
        'risk_factors': [],
        'opportunities': [],
      };

      final prediction = YieldPrediction.fromInference(inferenceResult);

      // Confidence based on coefficient of variation
      final cv = 100.0 / 3500.0;
      final expectedConfidence = 1.0 - (cv / 2);

      expect(prediction.confidence, closeTo(expectedConfidence, 0.01));
    });

    test('YieldPrediction.toMap serialization', () {
      final prediction = YieldPrediction(
        estimatedYield: 4200.0,
        lowerBound: 4000.0,
        upperBound: 4400.0,
        confidence: 0.88,
        riskFactors: ['Risk 1', 'Risk 2'],
        opportunities: ['Opp 1', 'Opp 2'],
      );

      final map = prediction.toMap();

      expect(map['estimatedYield'], 4200.0);
      expect(map['lowerBound'], 4000.0);
      expect(map['upperBound'], 4400.0);
      expect(map['confidence'], 0.88);
      expect(map['riskFactors'], isA<String>());
      expect(map['opportunities'], isA<String>());
    });

    test('YieldPrediction.fromMap deserialization', () {
      final map = {
        'estimatedYield': '3800.0',
        'lowerBound': '3600.0',
        'upperBound': '4000.0',
        'confidence': '0.82',
        'riskFactors': 'Pest outbreak,Flood risk',
        'opportunities': 'Early planting,Crop rotation',
      };

      final prediction = YieldPrediction.fromMap(map);

      expect(prediction.estimatedYield, 3800.0);
      expect(prediction.lowerBound, 3600.0);
      expect(prediction.confidence, 0.82);
      expect(prediction.riskFactors.length, 2);
      expect(prediction.opportunities.length, 2);
    });

    test('YieldPrediction.copyWith', () {
      final original = YieldPrediction(
        estimatedYield: 3000.0,
        lowerBound: 2800.0,
        upperBound: 3200.0,
        confidence: 0.75,
        riskFactors: ['Risk 1'],
        opportunities: ['Opp 1'],
      );

      final updated = original.copyWith(
        estimatedYield: 3500.0,
        confidence: 0.90,
      );

      expect(updated.estimatedYield, 3500.0);
      expect(updated.confidence, 0.90);
      expect(updated.lowerBound, 2800.0); // unchanged
      expect(updated.riskFactors.length, 1); // unchanged
    });

    test('YieldPrediction equality', () {
      final pred1 = YieldPrediction(
        estimatedYield: 3500.0,
        lowerBound: 3300.0,
        upperBound: 3700.0,
        confidence: 0.85,
        riskFactors: ['Risk'],
        opportunities: ['Opp'],
      );

      final pred2 = YieldPrediction(
        estimatedYield: 3500.0,
        lowerBound: 3300.0,
        upperBound: 3700.0,
        confidence: 0.85,
        riskFactors: ['Risk'],
        opportunities: ['Opp'],
      );

      expect(pred1, pred2);
    });

    test('YieldPrediction with zero standard deviation', () {
      final inferenceResult = {
        'yield': 3500.0,
        'std_dev': 0.0,
        'risk_factors': [],
        'opportunities': [],
      };

      final prediction = YieldPrediction.fromInference(inferenceResult);

      expect(prediction.estimatedYield, 3500.0);
      expect(prediction.lowerBound, 3500.0);
      expect(prediction.upperBound, 3500.0);
      expect(prediction.confidence, 1.0);
    });

    test('YieldPrediction with empty risk factors and opportunities', () {
      final prediction = YieldPrediction(
        estimatedYield: 3500.0,
        lowerBound: 3300.0,
        upperBound: 3700.0,
        confidence: 0.85,
        riskFactors: [],
        opportunities: [],
      );

      expect(prediction.riskFactors, isEmpty);
      expect(prediction.opportunities, isEmpty);
    });

    test('YieldPrediction interval width for narrow bounds', () {
      final prediction = YieldPrediction(
        estimatedYield: 3500.0,
        lowerBound: 3450.0,
        upperBound: 3550.0,
        confidence: 0.95,
        riskFactors: [],
        opportunities: [],
      );

      expect(prediction.intervalWidth, 100.0);
      expect(prediction.isReliable, true);
    });

    test('YieldPrediction interval width for wide bounds', () {
      final prediction = YieldPrediction(
        estimatedYield: 3500.0,
        lowerBound: 2500.0,
        upperBound: 4500.0,
        confidence: 0.40,
        riskFactors: [],
        opportunities: [],
      );

      expect(prediction.intervalWidth, 2000.0);
      expect(prediction.isReliable, false);
    });

    test('YieldPrediction toString does not crash', () {
      final prediction = YieldPrediction(
        estimatedYield: 3500.0,
        lowerBound: 3300.0,
        upperBound: 3700.0,
        confidence: 0.85,
        riskFactors: ['Risk'],
        opportunities: ['Opp'],
      );

      final str = prediction.toString();
      expect(str, contains('YieldPrediction'));
      expect(str, contains('3500'));
    });

    test('YieldPrediction with high yield and wide interval', () {
      final prediction = YieldPrediction(
        estimatedYield: 5000.0,
        lowerBound: 4000.0,
        upperBound: 6000.0,
        confidence: 0.50,
        riskFactors: ['Multiple risks'],
        opportunities: ['Several opportunities'],
      );

      expect(prediction.intervalWidth, 2000.0);
      expect(prediction.isReliable, false);
    });
  });
}
