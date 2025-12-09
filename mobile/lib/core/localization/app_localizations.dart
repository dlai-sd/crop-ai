import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  static AppLocalizations? _current;
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  Future<bool> load() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/translations/${locale.languageCode}.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      _localizedStrings = jsonMap;
      return true;
    } catch (e) {
      return false;
    }
  }

  String translate(String key) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;
    
    for (final k in keys) {
      if (value is Map) {
        value = value[k];
      } else {
        return key;
      }
    }
    
    return value?.toString() ?? key;
  }

  String get appName => translate('appName');
  String get appDescription => translate('appDescription');

  // Common
  String get loading => translate('common.loading');
  String get error => translate('common.error');
  String get retry => translate('common.retry');
  String get cancel => translate('common.cancel');
  String get save => translate('common.save');
  String get delete => translate('common.delete');
  String get edit => translate('common.edit');
  String get add => translate('common.add');
  String get submit => translate('common.submit');
  String get close => translate('common.close');
  String get next => translate('common.next');
  String get back => translate('common.back');
  String get yes => translate('common.yes');
  String get no => translate('common.no');
  String get ok => translate('common.ok');
  String get search => translate('common.search');

  // Farms
  String get farmTitle => translate('farms.title');
  String get farmEmpty => translate('farms.empty');
  String get farmAddFirst => translate('farms.addFirst');
  String get farmAddFarm => translate('farms.addFarm');
  String get farmDetails => translate('farms.farmDetails');
  String get farmLocation => translate('farms.location');
  String get farmArea => translate('farms.area');
  String get farmHectares => translate('farms.hectares');
  String get farmCropType => translate('farms.cropType');
  String get farmPlantingDate => translate('farms.plantingDate');
  String get farmExpectedHarvest => translate('farms.expectedHarvest');
  String get farmSoilMoisture => translate('farms.soilMoisture');
  String get farmTemperature => translate('farms.temperature');
  String get farmHealthStatus => translate('farms.healthStatus');
  String get farmHealthy => translate('farms.healthy');
  String get farmWarning => translate('farms.warning');
  String get farmCritical => translate('farms.critical');

  // Weather
  String get weatherTitle => translate('weather.title');
  String get weatherTemperature => translate('weather.temperature');
  String get weatherFeelsLike => translate('weather.feelsLike');
  String get weatherHumidity => translate('weather.humidity');
  String get weatherRainfall => translate('weather.rainfall');
  String get weatherWindSpeed => translate('weather.windSpeed');
  String get weatherUVIndex => translate('weather.uvIndex');
  String get weatherForecast => translate('weather.forecast');
  String get weatherCondition => translate('weather.condition');
  String get weatherLastUpdated => translate('weather.lastUpdated');
  String get weatherLowRisk => translate('weather.lowRisk');
  String get weatherModerateRisk => translate('weather.moderateRisk');
  String get weatherHighRisk => translate('weather.highRisk');
  String get weatherVeryHighRisk => translate('weather.veryHighRisk');
  String get weatherExtremeRisk => translate('weather.extremeRisk');

  // Settings
  String get settingsTitle => translate('settings.title');
  String get settingsLanguage => translate('settings.language');
  String get settingsNotifications => translate('settings.notifications');
  String get settingsTheme => translate('settings.theme');
  String get settingsAbout => translate('settings.about');
  String get settingsPrivacy => translate('settings.privacy');

  // Languages
  String get langEnglish => translate('languages.english');
  String get langHindi => translate('languages.hindi');
  String get langTamil => translate('languages.tamil');
  String get langTelugu => translate('languages.telugu');
  String get langKannada => translate('languages.kannada');
  String get langMarathi => translate('languages.marathi');
  String get langGujarati => translate('languages.gujarati');
  String get langPunjabi => translate('languages.punjabi');
  String get langBengali => translate('languages.bengali');
  String get langOdia => translate('languages.odia');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'ta', 'te', 'kn', 'mr', 'gu', 'pa', 'bn', 'or']
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
