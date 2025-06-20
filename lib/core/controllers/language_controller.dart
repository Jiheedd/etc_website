import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageController extends GetxController {
  final RxString _currentLanguage = 'en'.obs;

  String get currentLanguage => _currentLanguage.value;

  void changeLanguage(String languageCode) {
    _currentLanguage.value = languageCode;
    Get.updateLocale(Locale(languageCode));
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'language_english'.tr;
      case 'ar':
        return 'language_arabic'.tr;
      case 'fr':
        return 'language_french'.tr;
      default:
        return 'language_english'.tr;
    }
  }
}
