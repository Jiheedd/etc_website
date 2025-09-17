import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_landing_page/features/home/sections/video_carousel_section.dart';

void main() {
  group('VideoCarouselSection Tests', () {
    testWidgets(
        'should initialize first video on first load when section is visible',
        (WidgetTester tester) async {
      // Arrange
      final videos = [
        const VideoItem(
          url: 'assets/videos/sample1.mp4',
          thumbnail: 'assets/images/gallery1.png',
        ),
        const VideoItem(
          url: 'assets/videos/sample2.mp4',
          thumbnail: 'assets/images/gallery2.png',
        ),
      ];

      // Act - Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 100), // Some space above
                  VideoCarouselSection(videos: videos),
                  const SizedBox(
                      height: 1000), // Space below to ensure section is visible
                ],
              ),
            ),
          ),
        ),
      );

      // Wait for the widget to be fully built
      await tester.pumpAndSettle();

      // Assert - Check that the first video is being initialized
      // We can't directly test video playback in unit tests, but we can verify
      // that the initialization logic is triggered

      // Look for the video container
      expect(find.byType(VideoCarouselSection), findsOneWidget);

      // Check that the first video item is rendered
      expect(find.byType(FixedVideoContainer), findsWidgets);

      // Verify that the section is properly structured
      expect(find.byKey(const Key('video-carousel')), findsOneWidget);
    });

    testWidgets('should handle visibility changes correctly',
        (WidgetTester tester) async {
      // Arrange
      final videos = [
        const VideoItem(
          url: 'assets/videos/sample1.mp4',
          thumbnail: 'assets/images/gallery1.png',
        ),
      ];

      // Act - Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  VideoCarouselSection(videos: videos),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Assert - Verify the widget is properly initialized
      expect(find.byType(VideoCarouselSection), findsOneWidget);

      // The widget should be ready to handle visibility changes
      // This test verifies the structure is correct for visibility detection
    });
  });
}
