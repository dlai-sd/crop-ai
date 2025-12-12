import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';

/// Supported languages in Agri-Pulse
enum AppLanguage {
  english('en', 'English'),
  hindi('hi', 'हिंदी'),
  tamil('ta', 'தமிழ்'),
  telugu('te', 'తెలుగు'),
  kannada('kn', 'ಕನ್ನಡ'),
  marathi('mr', 'मराठी'),
  bengali('bn', 'বাংলা'),
  punjabi('pa', 'ਪੰਜਾਬੀ');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Extension for easy access to localized strings
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class LocalizationService {
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('te'),
    Locale('kn'),
    Locale('mr'),
    Locale('bn'),
    Locale('pa'),
  ];

  static Locale getLocaleFromLanguage(AppLanguage language) {
    return Locale(language.code);
  }

  static AppLanguage getLanguageFromLocale(Locale? locale) {
    if (locale == null) return AppLanguage.english;
    return AppLanguage.fromCode(locale.languageCode);
  }
}
