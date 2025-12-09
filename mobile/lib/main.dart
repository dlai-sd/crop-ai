import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/core/theme/app_theme.dart';
import 'package:crop_ai/core/routing/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CropAiApp(),
    ),
  );
}

class CropAiApp extends ConsumerWidget {
  const CropAiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Crop AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
