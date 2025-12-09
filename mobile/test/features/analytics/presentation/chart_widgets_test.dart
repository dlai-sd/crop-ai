import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/analytics/presentation/widgets/chart_widgets.dart';

void main() {
  group('DiseaseChartWidget', () {
    testWidgets('Renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: Scaffold(
              body: DiseaseChartWidget(farmId: 'farm_001'),
            ),
          ),
        ),
      );

      expect(find.text('Disease Trend (30 Days)'), findsOneWidget);
    });
  });

  group('YieldChartWidget', () {
    testWidgets('Renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: Scaffold(
              body: YieldChartWidget(farmId: 'farm_001'),
            ),
          ),
        ),
      );

      expect(find.text('Yield Forecast (5 Seasons)'), findsOneWidget);
    });
  });

  group('SeverityDistributionChart', () {
    testWidgets('Renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: Scaffold(
              body: SeverityDistributionChart(farmId: 'farm_001'),
            ),
          ),
        ),
      );

      expect(find.text('Disease Severity Distribution'), findsOneWidget);
    });
  });

  group('CommonDiseasesChart', () {
    testWidgets('Renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: Scaffold(
              body: CommonDiseasesChart(farmId: 'farm_001'),
            ),
          ),
        ),
      );

      expect(find.text('Top 5 Diseases'), findsOneWidget);
    });
  });

  group('ConfidenceTrendChart', () {
    testWidgets('Renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderContainer(
          child: MaterialApp(
            home: Scaffold(
              body: ConfidenceTrendChart(farmId: 'farm_001'),
            ),
          ),
        ),
      );

      expect(find.text('Yield Confidence Trend'), findsOneWidget);
    });
  });
}
