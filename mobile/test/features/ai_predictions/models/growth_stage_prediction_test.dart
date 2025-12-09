import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/ai_predictions/models/growth_stage_prediction.dart';

void main() {
  group('GrowthStage', () {
    test('GrowthStage enum has all 6 values', () {
      expect(GrowthStage.values.length, 6);
    });

    test('GrowthStage order is correct', () {
      expect(GrowthStage.values[0], GrowthStage.seedling);
      expect(GrowthStage.values[1], GrowthStage.vegetative);
      expect(GrowthStage.values[2], GrowthStage.flowering);
      expect(GrowthStage.values[3], GrowthStage.fruitGrain);
      expect(GrowthStage.values[4], GrowthStage.mature);
      expect(GrowthStage.values[5], GrowthStage.harvestReady);
    });
  });

  group('GrowthStageExtension', () {
    test('GrowthStage.displayName returns correct names', () {
      expect(GrowthStage.seedling.displayName, 'Seedling');
      expect(GrowthStage.vegetative.displayName, 'Vegetative');
      expect(GrowthStage.flowering.displayName, 'Flowering');
      expect(GrowthStage.fruitGrain.displayName, 'Fruit/Grain');
      expect(GrowthStage.mature.displayName, 'Mature');
      expect(GrowthStage.harvestReady.displayName, 'Harvest Ready');
    });

    test('GrowthStage.emoji returns correct emojis', () {
      expect(GrowthStage.seedling.emoji, '🌱');
      expect(GrowthStage.vegetative.emoji, '🌿');
      expect(GrowthStage.flowering.emoji, '🌼');
      expect(GrowthStage.fruitGrain.emoji, '🌾');
      expect(GrowthStage.mature.emoji, '🌽');
      expect(GrowthStage.harvestReady.emoji, '🚜');
    });

    test('GrowthStage.weekStart returns correct weeks', () {
      expect(GrowthStage.seedling.weekStart, 0);
      expect(GrowthStage.vegetative.weekStart, 2);
      expect(GrowthStage.flowering.weekStart, 6);
      expect(GrowthStage.fruitGrain.weekStart, 9);
      expect(GrowthStage.mature.weekStart, 14);
      expect(GrowthStage.harvestReady.weekStart, 18);
    });

    test('GrowthStage.weekEnd returns correct weeks', () {
      expect(GrowthStage.seedling.weekEnd, 2);
      expect(GrowthStage.vegetative.weekEnd, 6);
      expect(GrowthStage.flowering.weekEnd, 9);
      expect(GrowthStage.fruitGrain.weekEnd, 14);
      expect(GrowthStage.mature.weekEnd, 18);
      expect(GrowthStage.harvestReady.weekEnd, 20);
    });
  });

  group('GrowthStagePrediction', () {
    test('GrowthStagePrediction creation with all fields', () {
      final prediction = GrowthStagePrediction(
        currentStage: GrowthStage.vegetative,
        daysInStage: 21.5,
        daysToNextStage: 14.0,
        recommendations: ['Water regularly', 'Monitor for pests'],
        stageMetrics: {'leafAreaIndex': 2.5, 'height': 45.0},
      );

      expect(prediction.currentStage, GrowthStage.vegetative);
      expect(prediction.daysInStage, 21.5);
      expect(prediction.daysToNextStage, 14.0);
      expect(prediction.recommendations.length, 2);
      expect(prediction.stageMetrics.length, 2);
    });

    test('GrowthStagePrediction.fromInference creates correct object', () {
      final inferenceResult = {
        'stage_id': 2,
        'stage_name': 'vegetative',
        'confidence': 0.92,
        'days_since_planting': 35.0,
      };

      final prediction = GrowthStagePrediction.fromInference(inferenceResult);

      expect(prediction.currentStage, GrowthStage.vegetative);
      expect(prediction.daysInStage, greaterThan(0));
      expect(prediction.daysToNextStage, greaterThan(0));
    });

    test('GrowthStagePrediction.fromInference for seedling stage', () {
      final inferenceResult = {
        'stage_id': 0,
        'stage_name': 'seedling',
        'confidence': 0.95,
        'days_since_planting': 7.0,
      };

      final prediction = GrowthStagePrediction.fromInference(inferenceResult);

      expect(prediction.currentStage, GrowthStage.seedling);
    });

    test('GrowthStagePrediction.fromInference for harvest ready stage', () {
      final inferenceResult = {
        'stage_id': 5,
        'stage_name': 'harvestReady',
        'confidence': 0.88,
        'days_since_planting': 140.0,
      };

      final prediction = GrowthStagePrediction.fromInference(inferenceResult);

      expect(prediction.currentStage, GrowthStage.harvestReady);
    });

    test('GrowthStagePrediction.getRecommendations returns stage-specific tips', () {
      final prediction = GrowthStagePrediction(
        currentStage: GrowthStage.flowering,
        daysInStage: 10.0,
        daysToNextStage: 15.0,
        recommendations: [],
        stageMetrics: {},
      );

      final recs = prediction.getRecommendations();

      expect(recs, isNotEmpty);
      expect(recs.length, lessThanOrEqualTo(5));
      expect(recs, everyElement(isA<String>()));
    });

    test('GrowthStagePrediction recommendations differ by stage', () {
      final seedlingRecs = GrowthStagePrediction(
        currentStage: GrowthStage.seedling,
        daysInStage: 5.0,
        daysToNextStage: 9.0,
        recommendations: [],
        stageMetrics: {},
      ).getRecommendations();

      final floweringRecs = GrowthStagePrediction(
        currentStage: GrowthStage.flowering,
        daysInStage: 15.0,
        daysToNextStage: 10.0,
        recommendations: [],
        stageMetrics: {},
      ).getRecommendations();

      // Recommendations should differ for different stages
      expect(seedlingRecs, isNot(floweringRecs));
    });

    test('GrowthStagePrediction.toMap serialization', () {
      final prediction = GrowthStagePrediction(
        currentStage: GrowthStage.flowering,
        daysInStage: 18.5,
        daysToNextStage: 12.0,
        recommendations: ['Rec 1', 'Rec 2'],
        stageMetrics: {'metric1': 10.0},
      );

      final map = prediction.toMap();

      expect(map['currentStage'], isA<String>());
      expect(map['daysInStage'], 18.5);
      expect(map['daysToNextStage'], 12.0);
      expect(map['recommendations'], isA<String>());
    });

    test('GrowthStagePrediction.fromMap deserialization', () {
      final map = {
        'currentStage': 'flowering',
        'daysInStage': '21.5',
        'daysToNextStage': '14.0',
        'recommendations': 'Rec1,Rec2,Rec3',
        'stageMetrics': 'key1:5.0;key2:10.0',
      };

      final prediction = GrowthStagePrediction.fromMap(map);

      expect(prediction.currentStage, GrowthStage.flowering);
      expect(prediction.daysInStage, 21.5);
      expect(prediction.daysToNextStage, 14.0);
      expect(prediction.recommendations.length, 3);
    });

    test('GrowthStagePrediction.copyWith', () {
      final original = GrowthStagePrediction(
        currentStage: GrowthStage.vegetative,
        daysInStage: 20.0,
        daysToNextStage: 15.0,
        recommendations: ['Rec 1'],
        stageMetrics: {'metric': 5.0},
      );

      final updated = original.copyWith(
        currentStage: GrowthStage.flowering,
        daysInStage: 25.0,
      );

      expect(updated.currentStage, GrowthStage.flowering);
      expect(updated.daysInStage, 25.0);
      expect(updated.daysToNextStage, 15.0); // unchanged
      expect(updated.recommendations.length, 1); // unchanged
    });

    test('GrowthStagePrediction equality', () {
      final pred1 = GrowthStagePrediction(
        currentStage: GrowthStage.flowering,
        daysInStage: 15.0,
        daysToNextStage: 20.0,
        recommendations: ['R1'],
        stageMetrics: {'m': 1.0},
      );

      final pred2 = GrowthStagePrediction(
        currentStage: GrowthStage.flowering,
        daysInStage: 15.0,
        daysToNextStage: 20.0,
        recommendations: ['R1'],
        stageMetrics: {'m': 1.0},
      );

      expect(pred1, pred2);
    });

    test('GrowthStagePrediction with empty recommendations', () {
      final prediction = GrowthStagePrediction(
        currentStage: GrowthStage.mature,
        daysInStage: 30.0,
        daysToNextStage: 5.0,
        recommendations: [],
        stageMetrics: {},
      );

      expect(prediction.recommendations, isEmpty);
      expect(prediction.stageMetrics, isEmpty);
    });

    test('GrowthStagePrediction toString does not crash', () {
      final prediction = GrowthStagePrediction(
        currentStage: GrowthStage.flowering,
        daysInStage: 15.0,
        daysToNextStage: 20.0,
        recommendations: ['Rec'],
        stageMetrics: {},
      );

      final str = prediction.toString();
      expect(str, contains('GrowthStagePrediction'));
      expect(str, contains('flowering'));
    });

    test('GrowthStagePrediction all stages can be processed', () {
      for (final stage in GrowthStage.values) {
        final prediction = GrowthStagePrediction(
          currentStage: stage,
          daysInStage: 10.0,
          daysToNextStage: 15.0,
          recommendations: [],
          stageMetrics: {},
        );

        expect(prediction.currentStage, stage);
        expect(prediction.getRecommendations(), isNotEmpty);
      }
    });

    test('GrowthStagePrediction days calculations are valid', () {
      final prediction = GrowthStagePrediction(
        currentStage: GrowthStage.vegetative,
        daysInStage: 25.0,
        daysToNextStage: 18.0,
        recommendations: [],
        stageMetrics: {},
      );

      expect(prediction.daysInStage, greaterThan(0));
      expect(prediction.daysToNextStage, greaterThan(0));
      expect(prediction.daysInStage, lessThan(200));
      expect(prediction.daysToNextStage, lessThan(100));
    });
  });
}
