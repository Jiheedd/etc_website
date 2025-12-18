import 'package:flutter/material.dart';
import 'package:flutter_landing_page/component/component.dart';
import 'package:flutter_landing_page/section/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoSection extends ConsumerWidget {
  const VideoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    final controller = YoutubePlayerController.fromVideoId(
      videoId: 'qTCd0H0vhbs',
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            // final offset = box.localToGlobal(Offset.zero).dy;
            // ref.read(scrollNotifierProvider.notifier).updateSectionPosition(
            //   section: Section.video,
            //   dy: offset,
            // );
            ref.read(scrollNotifierProvider.notifier).scrollToSection(
                  Section.videos,
                );
          }
        });

        return Container(
          key: const ValueKey(Section.videos),
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Text(
                'video_title'.tr,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: isLargeScreen ? 800 : double.infinity,
                height: isLargeScreen ? 450 : 250,
                child: YoutubePlayerScaffold(
                  controller: controller,
                  builder: (context, _) => YoutubePlayer(
                    controller: controller,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'video_subtitle'.tr,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
