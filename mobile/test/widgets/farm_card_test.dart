import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/providers/farm_provider.dart';
import '../../lib/widgets/farm_card.dart';

void main() {
  group('FarmCard Widget', () {
    testWidgets('FarmCard renders all farm information', (WidgetTester tester) async {
      final farm = Farm(
        id: 'farm_001',
        userId: 'user_001',
        name: 'Green Valley Farm',
        location: 'Jaipur, Rajasthan',
        area: 15.5,
        farmType: 'Vegetable',
        currentCrop: 'Tomato',
        growthStage: 'Flowering',
        soilHealthScore: 72.0,
        moistureLevel: 65.0,
        phLevel: 6.8,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FarmCard(
              farm: farm,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Green Valley Farm'), findsOneWidget);
      expect(find.text('Jaipur, Rajasthan'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('Flowering'), findsOneWidget);
      expect(find.text('Vegetable'), findsOneWidget);
      expect(find.text('65.0%'), findsOneWidget);
      expect(find.text('6.8'), findsOneWidget);
      expect(find.text('15.5 ha'), findsOneWidget);
    });

    testWidgets('FarmCard shows health score in badge', (WidgetTester tester) async {
      final farm = Farm(
        id: 'farm_001',
        userId: 'user_001',
        name: 'Green Valley Farm',
        location: 'Jaipur, Rajasthan',
        area: 15.5,
        farmType: 'Vegetable',
        currentCrop: 'Tomato',
        growthStage: 'Flowering',
        soilHealthScore: 72.0,
        moistureLevel: 65.0,
        phLevel: 6.8,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FarmCard(
              farm: farm,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('72'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
    });

    testWidgets('FarmCard has View Details button', (WidgetTester tester) async {
      final farm = Farm(
        id: 'farm_001',
        userId: 'user_001',
        name: 'Green Valley Farm',
        location: 'Jaipur, Rajasthan',
        area: 15.5,
        farmType: 'Vegetable',
        currentCrop: 'Tomato',
        growthStage: 'Flowering',
        soilHealthScore: 72.0,
        moistureLevel: 65.0,
        phLevel: 6.8,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FarmCard(
              farm: farm,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('View Details'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('FarmCard calls onTap when tapped', (WidgetTester tester) async {
      var tapped = false;

      final farm = Farm(
        id: 'farm_001',
        userId: 'user_001',
        name: 'Green Valley Farm',
        location: 'Jaipur, Rajasthan',
        area: 15.5,
        farmType: 'Vegetable',
        currentCrop: 'Tomato',
        growthStage: 'Flowering',
        soilHealthScore: 72.0,
        moistureLevel: 65.0,
        phLevel: 6.8,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FarmCard(
              farm: farm,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('View Details'));

      expect(tapped, true);
    });

    testWidgets('FarmCard shows different health score colors', (WidgetTester tester) async {
      final goodHealthFarm = Farm(
        id: 'farm_001',
        userId: 'user_001',
        name: 'Good Farm',
        location: 'Jaipur',
        area: 15.5,
        farmType: 'Vegetable',
        currentCrop: 'Tomato',
        growthStage: 'Flowering',
        soilHealthScore: 85.0,
        moistureLevel: 65.0,
        phLevel: 6.8,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FarmCard(
              farm: goodHealthFarm,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('85'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FarmCard(
              farm: goodHealthFarm.copyWith(soilHealthScore: 35.0),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('35'), findsOneWidget);
    });
  });
}
