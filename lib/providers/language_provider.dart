import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en'); // تعيين اللغة الافتراضية
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  LanguageProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['en', 'ar'].contains(locale.languageCode)) return; // دعم اللغة الإنجليزية والعربية فقط
    _locale = locale;
    _storage.write(key: 'selectedLocale', value: locale.languageCode); // حفظ اللغة المختارة
    notifyListeners();
  }

  Future<void> _loadLocale() async {
    String? langCode = await _storage.read(key: 'selectedLocale');
    if (langCode != null) {
      _locale = Locale(langCode);
      notifyListeners();
    }
  }
}
