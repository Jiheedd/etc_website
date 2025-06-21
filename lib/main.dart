import 'dart:io';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_landing_page/component/component.dart';
import 'package:flutter_landing_page/core/controllers/language_controller.dart';
import 'package:flutter_landing_page/core/translations/app_translations.dart';
import 'package:flutter_landing_page/features/home/sections/video_carousel_section.dart';
import 'package:flutter_landing_page/first_view.dart';
import 'package:flutter_landing_page/header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'features/home/sections/gallery_section.dart';
import 'features/home/sections/intro_section.dart';
import 'features/home/sections/join_us_section.dart';
import 'footer.dart';

void main() {
  Get.put(LanguageController());
  runApp(
    ProviderScope(
      child: DevicePreview(
        enabled: !kIsWeb && Platform.isMacOS && kDebugMode,
        builder: (context) => const MainApp(),
      ),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GetMaterialApp(
      builder: (context, child) {
        return ShadApp(
          theme: ShadThemeData(
            colorScheme: ShadColorScheme(
              background: Colors.white,
              foreground: Colors.black87,
              card: const Color(0xFFF5F7FA),
              cardForeground: Colors.black,
              popover: const Color(0xFFE9EDF1),
              popoverForeground: Colors.black,
              primary: const Color(0xFF1A2A38),
              primaryForeground: Colors.white,
              secondary: const Color(0xFFC49A3A),
              secondaryForeground: Colors.black,
              muted: Colors.grey.shade200,
              mutedForeground: Colors.black45,
              accent: const Color(0xFF1A2A38),
              accentForeground: Colors.white,
              destructive: Colors.red.shade600,
              destructiveForeground: Colors.white,
              border: Colors.grey.shade300,
              input: Colors.grey.shade100,
              ring: const Color(0xFF1A2A38).withOpacity(0.2),
              selection: const Color(0xFFE0E0E0),
            ),
            brightness: Brightness.light,
          ),
          darkTheme: ShadThemeData(
            colorScheme: ShadColorScheme(
              background: const Color(0xFF121E28),
              foreground: Colors.white,
              card: const Color(0xFF1C2A3A),
              cardForeground: Colors.white,
              popover: const Color(0xFF1F2E40),
              popoverForeground: Colors.white,
              primary: Colors.white,
              primaryForeground: Colors.black,
              secondary: const Color(0xFFADB5BD),
              secondaryForeground: Colors.black,
              muted: const Color(0xFF2C3A4C),
              mutedForeground: Colors.white60,
              accent: const Color(0xFFFFFFFF),
              accentForeground: Colors.black,
              destructive: const Color(0xFFEF5350),
              destructiveForeground: Colors.white,
              border: const Color(0xFF2F3E50),
              input: const Color(0xFF1E2B3B),
              ring: const Color(0xFFC49A3A).withOpacity(0.2),
              selection: const Color(0xFF2E3D50),
            ),
            brightness: Brightness.dark,
          ),
          themeMode: ref.watch(themeNotifierProvider),
          builder: (context, theme) {
            return ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            );
          },
        );
      },
      title: 'ETC - Echi Training Center',
      translations: AppTranslations(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en'),
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
      ],
      home: Scaffold(
        appBar: const Header(),
        body: SingleChildScrollView(
          controller: ref.watch(
            scrollNotifierProvider.select((s) => s.controller),
          ),
          child: const Column(
            children: [
              FirstView(),
              IntroSection(),
              // VideoCarouselSection(videos: sampleVideos),
              VideoCarouselSection(
                videos: [
                  VideoItem(
                    // title: 'Sample 1',
                    url: 'assets/videos/sample1.mp4',
                    thumbnail: 'assets/images/gallery1.png',
                  ),
                  VideoItem(
                    // title: 'Sample 2',
                    url: 'assets/videos/sample2.mp4',
                    thumbnail: 'assets/images/gallery2.png',
                  ),
                  VideoItem(
                    // title: 'Sample 3',
                    url: 'assets/videos/sample3.mp4',
                    thumbnail: 'assets/images/gallery3.png',
                  ),
                  VideoItem(
                    // title: 'Sample 4',
                    url: 'assets/videos/sample4.mp4',
                    thumbnail: 'assets/images/gallery4.png',
                  ),
                ],
              ),
              // const VideoSection(),
              GallerySection(),
              JoinUsSection(),
              Footer(),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
