import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageController extends GetxController {
  // Keep controller state in sync with GetX locale.
  // Default to French when no locale is set yet.
  final RxString _currentLanguage = 'fr'.obs;

  String get currentLanguage => _currentLanguage.value;

  @override
  void onInit() {
    super.onInit();
    final code = Get.locale?.languageCode ?? 'fr';
    _currentLanguage.value = code;

    // Ensure GetX has a locale set (prevents mismatch between controller and Get.locale).
    if (Get.locale == null) {
      Get.updateLocale(Locale(code));
    }
  }

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
