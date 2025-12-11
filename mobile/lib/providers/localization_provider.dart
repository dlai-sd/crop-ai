import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../services/localization_service.dart';

/// Provider for current app language
final appLanguageProvider = StateProvider<AppLanguage>((ref) {
  return AppLanguage.english;
});

/// Provider for current locale
final currentLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(appLanguageProvider);
  return LocalizationService.getLocaleFromLanguage(language);
});
