import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crop_ai/features/farm/screens/farm_list_screen.dart';
import 'package:crop_ai/features/farm/screens/farm_detail_screen.dart';

final goRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const FarmListScreen(),
      routes: [
        GoRoute(
          path: 'farm/:farmId',
          builder: (context, state) {
            final farmId = state.pathParameters['farmId']!;
            return FarmDetailScreen(farmId: farmId);
          },
        ),
      ],
    ),
  ],
  initialLocation: '/',
  debugLogDiagnostics: true,
);
