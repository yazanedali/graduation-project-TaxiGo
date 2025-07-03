import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/language/ar.dart'; // ملف الترجمات العربية
import 'package:taxi_app/language/en.dart'; // ملف الترجمات الإنجليزية

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': en, // ترجمة الإنجليزية
    'ar': ar, // ترجمة العربية
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // إضافة getter 'isRTL' هنا
  bool get isRTL {
    return locale.languageCode == 'ar'; // إذا كانت اللغة العربية، فهي RTL
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
