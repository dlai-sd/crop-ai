import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/farm_list_screen.dart';
import 'screens/decision_board_screen.dart';
import 'screens/living_map_screen.dart';
import 'screens/magic_snap_screen.dart';
import 'screens/geospatial_chat_screen.dart';
import 'providers/app_providers.dart';
import 'providers/localization_provider.dart';
import 'services/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: DlaiCropApp()));
}

class DlaiCropApp extends ConsumerWidget {
  const DlaiCropApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentLocale = ref.watch(currentLocaleProvider);
    final appLanguage = ref.watch(appLanguageProvider);

    final router = GoRouter(
      initialLocation: authState.isAuthenticated ? '/home' : '/login',
      redirect: (context, state) {
        if (!authState.isAuthenticated && state.fullPath != '/login') {
          return '/login';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const FarmListScreen(),
        ),
        GoRoute(
          path: '/decision-board',
          builder: (context, state) => const DecisionBoardScreen(),
        ),
        GoRoute(
          path: '/living-map',
          builder: (context, state) => const LivingMapScreen(),
        ),
        GoRoute(
          path: '/magic-snap',
          builder: (context, state) => const MagicSnapScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const GeospatialChatScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Agri-Pulse',
      theme: appTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocalizationService.supportedLocales,
    );
  }
}
