// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:rxdart/rxdart.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoItem {
  const VideoItem({required this.url, required this.thumbnail});
  final String url;
  final String thumbnail;
}

// Fixed size video container widget
class FixedVideoContainer extends StatelessWidget {
  const FixedVideoContainer({
    super.key,
    required this.child,
    required this.isMain,
  });
  final Widget child;
  final bool isMain;

  // Fixed video dimensions - these never change
  static const videoWidth = 280.0;
  static const videoHeight = 498.0; // 9:16 aspect ratio
  static const spacing = 5.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: videoWidth,
      height: videoHeight,
      margin: const EdgeInsets.symmetric(horizontal: spacing),
      transform: Matrix4.identity()..scale(isMain ? 1.0 : 0.92),
      child: child,
    );
  }
}

// Sound control widget - always in top-right corner
class VideoSoundControl extends StatelessWidget {
  const VideoSoundControl({
    super.key,
    required this.isMuted,
    required this.onToggleMute,
  });
  final bool isMuted;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        onTap: onToggleMute,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
// play/stop control widget - always in top-left corner
class VideoPlayStopControl extends StatelessWidget {
  const VideoPlayStopControl({
    super.key,
    required this.isPlaying,
    required this.onTogglePlayPause,
  });
  final bool isPlaying;
  final VoidCallback onTogglePlayPause;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: GestureDetector(
        onTap: onTogglePlayPause,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// Fullscreen control widget - always in top-left corner
class VideoFullscreenControl extends StatelessWidget {
  const VideoFullscreenControl({
    super.key,
    required this.onFullscreen,
  });
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: GestureDetector(
        onTap: onFullscreen,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.fullscreen,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// Play/Pause overlay widget
class VideoPlayPauseOverlay extends StatelessWidget {
  const VideoPlayPauseOverlay({
    super.key,
    required this.isVisible,
  });
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.play_circle_fill,
          size: 64,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }
}

class VideoCarouselSection extends StatefulWidget {
  const VideoCarouselSection({
    super.key,
    required this.videos,
    this.autoPlayDelay = const Duration(milliseconds: 500),
  });
  final List<VideoItem> videos;
  final Duration autoPlayDelay;

  @override
  State<VideoCarouselSection> createState() => _VideoCarouselSectionState();
}

class _VideoCarouselSectionState extends State<VideoCarouselSection> {
  // Controllers and state management
  PageController? _pageController;
  late final BehaviorSubject<int> _currentIndex$;
  late final BehaviorSubject<bool> _muted$;
  late final BehaviorSubject<bool> _isPlaying$;
  late final BehaviorSubject<bool> _isVisible$;
  late final BehaviorSubject<bool> _manuallyPaused$;

  // Video management - Map of controllers for better lifecycle management
  final Map<int, VideoPlayerController> _videoControllers = {};
  VideoPlayerController? _activeController;
  Timer? _autoPlayTimer;
  StreamSubscription? _videoEndSubscription;

  // State flags
  bool _isInitializing = false;
  bool _isInFullscreen = false;
  bool _hasEverBeenVisible = false;

  // Layout management
  var _visibleVideosCount = 3;
  double _lastScreenWidth = 0;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    _currentIndex$ = BehaviorSubject.seeded(0);
    _muted$ = BehaviorSubject.seeded(false);
    _isPlaying$ = BehaviorSubject.seeded(false);
    _isVisible$ = BehaviorSubject.seeded(false);
    _manuallyPaused$ = BehaviorSubject.seeded(false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePageController();
    });
  }

  void _initializePageController() {
    final screenWidth = MediaQuery.of(context).size.width;
    _updateLayoutForScreenSize(screenWidth);

    _pageController = PageController(
      viewportFraction: _calculateViewportFraction(screenWidth),
    );

    if (mounted) setState(() {});
  }

  void _updateLayoutForScreenSize(double screenWidth) {
    if ((screenWidth - _lastScreenWidth).abs() < 50) return;

    const videoWidth = FixedVideoContainer.videoWidth;
    const spacing = FixedVideoContainer.spacing * 2;

    var maxVideos = ((screenWidth - 60) / (videoWidth + spacing)).floor();
    _visibleVideosCount = maxVideos.clamp(3, 5);
    _lastScreenWidth = screenWidth;

    debugPrint(
        'Screen: ${screenWidth.toInt()}px → $_visibleVideosCount videos');
  }

  double _calculateViewportFraction(double screenWidth) {
    const videoWidth = FixedVideoContainer.videoWidth;
    const spacing = FixedVideoContainer.spacing * 2;
    return (videoWidth + spacing) / screenWidth;
  }

  // Safe controller check
  bool _isControllerValid(VideoPlayerController? controller) {
    return controller != null &&
        controller.value.isInitialized &&
        !controller.value.hasError;
  }

  // Get or create controller for a specific index
  Future<VideoPlayerController?> _getOrCreateController(int index) async {
    if (_videoControllers.containsKey(index)) {
      final controller = _videoControllers[index]!;
      if (_isControllerValid(controller)) {
        return controller;
      } else {
        // Controller is invalid, remove it
        _videoControllers.remove(index);
      }
    }

    if (index >= widget.videos.length) return null;

    try {
      final video = widget.videos[index];
      final controller = VideoPlayerController.network(video.url);
      await controller.initialize();

      if (mounted) {
        _videoControllers[index] = controller;
        controller.setLooping(false);
        controller.setVolume(_muted$.value ? 0 : 1);
        return controller;
      } else {
        controller.dispose();
        return null;
      }
    } catch (e) {
      debugPrint('Error initializing video controller for index $index: $e');
      return null;
    }
  }

  // Visibility-Triggered Autoplay Logic
  void _onVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction >= 0.5;
    _isVisible$.add(isVisible);

    if (!isVisible) {
      // Pause when out of view
      _pauseVideoIfPlaying();
    } else {
      if (!_hasEverBeenVisible) {
        // First time visible - initialize video
        _hasEverBeenVisible = true;
        _initializeCurrentVideo();
      } else {
        // Resume only if not manually paused
        _resumeVideoIfNeeded();
      }
    }
  }

  void _pauseVideoIfPlaying() {
    if (_isControllerValid(_activeController) &&
        _activeController!.value.isPlaying) {
      _activeController!.pause();
      _isPlaying$.add(false);
    }
  }

  void _resumeVideoIfNeeded() {
    if (_isControllerValid(_activeController) &&
        !_manuallyPaused$.value &&
        !_activeController!.value.isPlaying) {
      _activeController!.play();
      _isPlaying$.add(true);
    }
  }

  // Initialize current video
  Future<void> _initializeCurrentVideo() async {
    if (_isInitializing || widget.videos.isEmpty) return;

    _isInitializing = true;
    final currentIndex = _currentIndex$.value;

    try {
      // Get or create controller for current index
      final controller = await _getOrCreateController(currentIndex);

      if (!mounted) return;

      if (controller != null) {
        _activeController = controller;
        _setupVideoEndListener(controller);

        // Auto-play only if visible and not manually paused
        if (_isVisible$.value && !_manuallyPaused$.value) {
          await controller.play();
          _isPlaying$.add(true);
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error initializing video: $e');
      _moveToNextVideo();
    } finally {
      _isInitializing = false;
    }
  }

// Updated _setupVideoEndListener to only listen to the active controller
  void _setupVideoEndListener(VideoPlayerController controller) {
    _videoEndSubscription?.cancel();
    _videoEndSubscription = controller.addListener(() {
      if (!_isControllerValid(controller) || controller != _activeController) return;

      final value = controller.value;
      if (value.position >= value.duration &&
          value.duration > Duration.zero &&
          value.position > Duration.zero &&
          !value.isBuffering) {
        _onVideoEnded();
      }
    }) as StreamSubscription?;
  }

  void _onVideoEnded() {
    if (!mounted) return;
    debugPrint('Video ended - moving to next video automatically');
    _isPlaying$.add(false);
    _autoPlayTimer?.cancel();
    _moveToNextVideo();
  }

  void _moveToNextVideo() {
    if (!mounted) return;

    final currentIndex = _currentIndex$.value;
    final nextIndex = (currentIndex + 1) % widget.videos.length;

    _pageController!.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _moveToPreviousVideo() {
    if (!mounted) return;

    final currentIndex = _currentIndex$.value;
    final previousIndex =
        (currentIndex - 1 + widget.videos.length) % widget.videos.length;

    _pageController!.animateToPage(
      previousIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (_currentIndex$.value == index) return;

    _currentIndex$.add(index);
    _isPlaying$.add(false);
    _autoPlayTimer?.cancel();
    _manuallyPaused$.add(false); // Reset manual pause flag on page change

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _initializeCurrentVideo();
      }
    });
  }

  void _startAutoPlay() {
    if (_autoPlayTimer != null) return;

    _autoPlayTimer = Timer.periodic(widget.autoPlayDelay, (timer) {
      if (!_isControllerValid(_activeController)) return;

      if (_activeController!.value.isPlaying) return;

      _togglePlayPause();
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant VideoCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videos != widget.videos) {
      _initializeCurrentVideo();
    }
  }

  void _togglePlayPause() {
    if (!_isControllerValid(_activeController)) return;

    _autoPlayTimer?.cancel();

    if (_activeController!.value.isPlaying) {
      _activeController!.pause();
      _isPlaying$.add(false);
      _manuallyPaused$.add(true); // Track manual pause
    } else {
      _activeController!.play();
      _isPlaying$.add(true);
      _manuallyPaused$.add(false); // Reset manual pause flag
    }
  }

  void _toggleMute() {
    final muted = !_muted$.value;
    _muted$.add(muted);

    // Update volume for all controllers
    for (final controller in _videoControllers.values) {
      if (_isControllerValid(controller)) {
        controller.setVolume(muted ? 0 : 1);
      }
    }
  }

  void _onVideoTap(int index) {
    print('Video tapped at index: $index');
    if (index == _currentIndex$.value) {
      _togglePlayPause();
    } else {
      _pageController!.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _videoEndSubscription?.cancel();

    // Dispose all controllers
    for (final controller in _videoControllers.values) {
      try {
        controller.pause();
        controller.dispose();
      } catch (e) {
        debugPrint('Error disposing controller: $e');
      }
    }
    _videoControllers.clear();

    _pageController?.dispose();
    _currentIndex$.close();
    _muted$.close();
    _isPlaying$.close();
    _isVisible$.close();
    _manuallyPaused$.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const height = FixedVideoContainer.videoHeight + 20;

    if (_pageController == null) {
      return const SizedBox(
        height: height,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _handleScreenSizeChange(constraints.maxWidth);

        return VisibilityDetector(
          key: const Key('video-carousel'),
          onVisibilityChanged: _onVisibilityChanged,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: StreamBuilder<int>(
              stream: _currentIndex$,
              builder: (context, snapshot) {
                final currentIndex = snapshot.data ?? 0;

                return PageView.builder(
                  controller: _pageController!,
                  onPageChanged: _onPageChanged,
                  itemCount: widget.videos.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) =>
                      _buildVideoItem(index, currentIndex),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleScreenSizeChange(double currentWidth) {
    if ((currentWidth - _lastScreenWidth).abs() > 50) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateLayoutForScreenSize(currentWidth);
          _recreatePageController(currentWidth);
        }
      });
    }
  }

  void _recreatePageController(double currentWidth) {
    final oldController = _pageController;
    final currentPage = oldController?.hasClients == true
        ? oldController!.page?.round() ?? 0
        : 0;

    _pageController = PageController(
      viewportFraction: _calculateViewportFraction(currentWidth),
      initialPage: currentPage,
    );

    oldController?.dispose();
    setState(() {});
  }

  Widget _buildVideoItem(int index, int currentIndex) {
    final isMain = index == currentIndex;
    final video = widget.videos[index];

    return FixedVideoContainer(
      isMain: isMain,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Video or thumbnail
            Positioned.fill(
              child: isMain && _isControllerValid(_activeController)
                  ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _activeController!.value.size.width,
                  height: _activeController!.value.size.height,
                  child: VideoPlayer(_activeController!),
                ),
              )
                  : Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(video.thumbnail),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // // Play/Pause overlay
            // if (isMain)
            //   Positioned.fill(
            //     child: StreamBuilder<bool>(
            //       stream: _isPlaying$,
            //       builder: (context, snapshot) {
            //         final isPlaying = snapshot.data ?? false;
            //         return Center(
            //           child: VideoPlayPauseOverlay(isVisible: !isPlaying),
            //         );
            //       },
            //     ),
            //   ),



            // Loading indicator
            if (isMain && _isInitializing)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),

            // Tap on video to toggle play/pause
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _onVideoTap(index),
                child: Container(
                  color: Colors.transparent, // Capture taps
                ),
              ),
            ),


            // Sound control
            if (isMain)
              StreamBuilder<bool>(
                stream: _muted$,
                builder: (context, snapshot) {
                  final muted = snapshot.data ?? false;
                  return VideoSoundControl(
                    isMuted: muted,
                    onToggleMute: _toggleMute,
                  );
                },
              ),
            // Play/Stop control
            if (isMain)
              StreamBuilder<bool>(
                stream: _isPlaying$,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return !isPlaying ? VideoPlayStopControl(
                    isPlaying: isPlaying,
                    onTogglePlayPause: _togglePlayPause,
                  ) : const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }
}

