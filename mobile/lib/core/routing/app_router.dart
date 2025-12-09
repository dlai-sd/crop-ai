import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crop_ai/features/farm/screens/farm_list_screen.dart';
import 'package:crop_ai/features/farm/screens/farm_detail_screen.dart';
import 'package:crop_ai/features/farm/screens/add_edit_farm_screen.dart';

final goRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const FarmListScreen(),
      routes: [
        GoRoute(
          path: 'farm/add',
          builder: (context, state) => const AddEditFarmScreen(),
        ),
        GoRoute(
          path: 'farm/:farmId',
          builder: (context, state) {
            final farmId = state.pathParameters['farmId']!;
            return FarmDetailScreen(farmId: farmId);
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final farmId = state.pathParameters['farmId']!;
                return AddEditFarmScreen(farmId: farmId);
              },
            ),
          ],
        ),
      ],
    ),
  ],
  initialLocation: '/',
  debugLogDiagnostics: true,
);
