import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoItem {
  final String url;
  final String thumbnail;
  const VideoItem({required this.url, required this.thumbnail});
}

class VideoCarouselSection extends StatefulWidget {
  final List<VideoItem> videos;
  const VideoCarouselSection({super.key, required this.videos});

  @override
  State<VideoCarouselSection> createState() => _VideoCarouselSectionState();
}

class _VideoCarouselSectionState extends State<VideoCarouselSection> {
  late final PageController _pageController;
  late final List<VideoPlayerController?> _videoControllers;
  late final BehaviorSubject<int> _currentIndex$;
  late final BehaviorSubject<bool> _muted$;
  late final BehaviorSubject<bool> _paused$;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7);
    _videoControllers = List.generate(widget.videos.length, (_) => null);
    _currentIndex$ = BehaviorSubject.seeded(0);
    _muted$ = BehaviorSubject.seeded(false);
    _paused$ = BehaviorSubject.seeded(false);
    _initVideoController(0);
  }

  Future<void> _initVideoController(int index) async {
    _disposeVideoController(index);
    final video = widget.videos[index];
    final controller = VideoPlayerController.network(video.url);
    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(_muted$.value ? 0 : 1);
    if (!_paused$.value) controller.play();
    _videoControllers[index] = controller;
    setState(() {});
  }

  void _disposeVideoController(int index) {
    _videoControllers[index]?.dispose();
    _videoControllers[index] = null;
  }

  void _onPageChanged(int index) async {
    final oldIndex = _currentIndex$.value;
    _currentIndex$.add(index);
    _videoControllers[oldIndex]?.pause();
    _paused$.add(false);
    await _initVideoController(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var c in _videoControllers) {
      c?.dispose();
    }
    _currentIndex$.close();
    _muted$.close();
    _paused$.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.9; // Like intro section
    final width = MediaQuery.of(context).size.width * 0.6; // Like intro section
    return SizedBox(
      height: height,
      // width: width,
      child: StreamBuilder<int>(
        stream: _currentIndex$,
        builder: (context, snapshot) {
          final currentIndex = snapshot.data ?? 0;
          return PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.videos.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final isMain = index == currentIndex;
              final controller = _videoControllers[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: isMain ? 12 : 24),
                color: isMain
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: controller?.value.aspectRatio ?? 9 / 16,
                      child: controller != null && controller.value.isInitialized
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: VideoPlayer(controller),
                      )
                          : Image.network(widget.videos[index].thumbnail,
                          fit: BoxFit.cover),
                    ),
                    if (isMain)
                      StreamBuilder<bool>(
                        stream: _paused$,
                        builder: (context, snapshot) {
                          final paused = snapshot.data ?? false;
                          return AnimatedOpacity(
                            opacity: paused ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.play_arrow,
                                size: 80, color: Colors.white.withOpacity(0.8)),
                          );
                        },
                      ),

                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            if (isMain) {
                              print("on tap main video");
                              final isPaused = _paused$.value;
                              _paused$.add(!isPaused);
                              if (isPaused) {
                                controller?.play();
                              } else {
                                controller?.pause();
                              }
                            } else {
                              _pageController.animateToPage(index,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut);
                            }
                          },
                        ),
                      ),
                    if (isMain)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: StreamBuilder<bool>(
                          stream: _muted$,
                          builder: (context, snapshot) {
                            final muted = snapshot.data ?? false;
                            return IconButton(
                              icon: Icon(
                                muted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                final newMuted = !muted;
                                _muted$.add(newMuted);
                                _videoControllers[currentIndex]
                                    ?.setVolume(newMuted ? 0 : 1);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}