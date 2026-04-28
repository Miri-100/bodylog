import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _language = 'English';

  String get language => _language;

  Locale get locale {
    switch (_language) {
      case 'Malay':
        return const Locale('ms');
      case 'Chinese':
        return const Locale('zh');
      case 'Spanish':
        return const Locale('es');
      case 'English':
      default:
        return const Locale('en');
    }
  }

  void setLanguage(String language) {
    _language = language;
    notifyListeners();
  }
}

final languageProvider = LanguageProvider();
