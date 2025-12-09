import 'package:flutter_test/flutter_test.dart';
import 'package:crop_ai/features/ai_predictions/data/ml_service.dart';

void main() {
  group('ImagePreprocessor', () {
    test('IMAGE_INPUT_SIZE constant is correct', () {
      expect(ImagePreprocessor.MODEL_INPUT_SIZE, 224);
    });

    test('Normalization constants are correct', () {
      expect(ImagePreprocessor.NORMALIZE_MIN, -1.0);
      expect(ImagePreprocessor.NORMALIZE_MAX, 1.0);
    });
  });

  group('FeatureEngineer', () {
    test('normalizeFeatures normalizes to [0,1]', () {
      final features = [10.0, 20.0, 30.0, 40.0, 50.0];
      final normalized = FeatureEngineer.normalizeFeatures(features);

      expect(normalized.length, 5);
      expect(normalized[0], 0.0);
      expect(normalized[4], 1.0);
      for (final f in normalized) {
        expect(f, greaterThanOrEqualTo(0.0));
        expect(f, lessThanOrEqualTo(1.0));
      }
    });

    test('normalizeFeatures handles single value', () {
      final features = [42.0];
      final normalized = FeatureEngineer.normalizeFeatures(features);

      expect(normalized.length, 1);
      expect(normalized[0], 0.5);
    });

    test('normalizeFeatures handles identical values', () {
      final features = [5.0, 5.0, 5.0, 5.0];
      final normalized = FeatureEngineer.normalizeFeatures(features);

      expect(normalized.length, 4);
      for (final f in normalized) {
        expect(f, 0.5);
      }
    });

    test('normalizeFeatures handles empty list', () {
      final features = <double>[];
      final normalized = FeatureEngineer.normalizeFeatures(features);

      expect(normalized, isEmpty);
    });

    test('normalizeFeatures handles negative values', () {
      final features = [-10.0, 0.0, 10.0, 20.0];
      final normalized = FeatureEngineer.normalizeFeatures(features);

      expect(normalized[0], 0.0);
      expect(normalized[2], closeTo(0.67, 0.01));
      expect(normalized[3], 1.0);
    });

    test('calculateStats returns correct statistics', () {
      final features = [10.0, 20.0, 30.0, 40.0, 50.0];
      final stats = FeatureEngineer.calculateStats(features);

      expect(stats['mean'], 30.0);
      expect(stats['min'], 10.0);
      expect(stats['max'], 50.0);
      expect(stats['std_dev'], isNotNull);
      expect(stats['std_dev'], greaterThan(0));
    });

    test('calculateStats with empty list', () {
      final stats = FeatureEngineer.calculateStats([]);

      expect(stats['mean'], 0.0);
      expect(stats['std_dev'], 0.0);
      expect(stats['min'], 0.0);
      expect(stats['max'], 0.0);
    });

    test('calculateStats with single value', () {
      final stats = FeatureEngineer.calculateStats([42.0]);

      expect(stats['mean'], 42.0);
      expect(stats['std_dev'], 0.0);
      expect(stats['min'], 42.0);
      expect(stats['max'], 42.0);
    });

    test('calculateStats with identical values', () {
      final stats = FeatureEngineer.calculateStats([7.0, 7.0, 7.0]);

      expect(stats['mean'], 7.0);
      expect(stats['std_dev'], 0.0);
    });

    test('calculateStats standard deviation calculation', () {
      // Variance of [1,2,3,4,5] is 2
      final stats = FeatureEngineer.calculateStats([1.0, 2.0, 3.0, 4.0, 5.0]);

      // Mean = 3, StdDev = sqrt(2) ≈ 1.414
      expect(stats['mean'], 3.0);
      expect(stats['std_dev'], closeTo(1.414, 0.01));
    });
  });

  group('MockMLService', () {
    late MockMLService mlService;

    setUp(() {
      mlService = MockMLService();
    });

    test('initialize completes successfully', () async {
      expect(mlService.initialize(), completes);
    });

    test('dispose completes successfully', () async {
      expect(mlService.dispose(), completes);
    });

    test('predictDisease returns valid result', () async {
      final imageBytes = List<int>.generate(100, (i) => i).toList();
      final result = await mlService.predictDisease(
        Uint8List.fromList(imageBytes),
      );

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('disease'), true);
      expect(result.containsKey('confidence'), true);
      expect(result['confidence'], isA<double>());
      expect(result['confidence'], greaterThan(0));
      expect(result['confidence'], lessThanOrEqualTo(1));
    });

    test('predictDisease returns treatments', () async {
      final imageBytes = List<int>.generate(100, (i) => i).toList();
      final result = await mlService.predictDisease(
        Uint8List.fromList(imageBytes),
      );

      expect(result.containsKey('treatments'), true);
      expect(result['treatments'], isA<List>());
    });

    test('predictYield returns valid result', () async {
      final features = [25.0, 150.0, 70.0, 6.5, 100.0, 50.0, 80.0];
      final result = await mlService.predictYield(features);

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('yield'), true);
      expect(result['yield'], isA<double>());
      expect(result['yield'], greaterThan(0));
    });

    test('predictYield returns standard deviation', () async {
      final features = [25.0, 150.0, 70.0, 6.5, 100.0, 50.0, 80.0];
      final result = await mlService.predictYield(features);

      expect(result.containsKey('std_dev'), true);
      expect(result['std_dev'], isA<double>());
      expect(result['std_dev'], greaterThanOrEqualTo(0));
    });

    test('predictYield returns risk factors and opportunities', () async {
      final features = [25.0, 150.0, 70.0, 6.5, 100.0, 50.0, 80.0];
      final result = await mlService.predictYield(features);

      expect(result.containsKey('risk_factors'), true);
      expect(result.containsKey('opportunities'), true);
      expect(result['risk_factors'], isA<List>());
      expect(result['opportunities'], isA<List>());
    });

    test('predictGrowthStage returns valid result', () async {
      final imageBytes = List<int>.generate(100, (i) => i).toList();
      final result = await mlService.predictGrowthStage(
        Uint8List.fromList(imageBytes),
      );

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('stage_name'), true);
      expect(result.containsKey('confidence'), true);
      expect(result['confidence'], isA<double>());
      expect(result['confidence'], greaterThan(0));
      expect(result['confidence'], lessThanOrEqualTo(1));
    });

    test('predictGrowthStage returns stage ID', () async {
      final imageBytes = List<int>.generate(100, (i) => i).toList();
      final result = await mlService.predictGrowthStage(
        Uint8List.fromList(imageBytes),
      );

      expect(result.containsKey('stage_id'), true);
      expect(result['stage_id'], isA<int>());
      expect(result['stage_id'], greaterThanOrEqualTo(0));
      expect(result['stage_id'], lessThan(6));
    });

    test('Mock predictions are consistent', () async {
      final imageBytes = List<int>.generate(100, (i) => i).toList();

      final result1 = await mlService.predictDisease(
        Uint8List.fromList(imageBytes),
      );
      final result2 = await mlService.predictDisease(
        Uint8List.fromList(imageBytes),
      );

      // Mock should return consistent results
      expect(result1['disease'], result2['disease']);
      expect(result1['confidence'], result2['confidence']);
    });

    test('predictDisease simulates processing delay', () async {
      final startTime = DateTime.now();
      final imageBytes = List<int>.generate(100, (i) => i).toList();

      await mlService.predictDisease(Uint8List.fromList(imageBytes));

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      expect(elapsed, greaterThanOrEqualTo(200)); // Min ~300ms delay
    });

    test('predictYield simulates processing delay', () async {
      final startTime = DateTime.now();
      final features = [25.0, 150.0, 70.0, 6.5, 100.0, 50.0, 80.0];

      await mlService.predictYield(features);

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      expect(elapsed, greaterThanOrEqualTo(100)); // Min ~200ms delay
    });

    test('predictGrowthStage simulates processing delay', () async {
      final startTime = DateTime.now();
      final imageBytes = List<int>.generate(100, (i) => i).toList();

      await mlService.predictGrowthStage(Uint8List.fromList(imageBytes));

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      expect(elapsed, greaterThanOrEqualTo(150)); // Min ~250ms delay
    });
  });
}
