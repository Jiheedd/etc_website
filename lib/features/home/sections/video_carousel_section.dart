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
  PageController? _pageController;
  late final BehaviorSubject<int> _currentIndex$;
  late final BehaviorSubject<bool> _muted$;
  late final BehaviorSubject<bool> _isPlaying$;

  VideoPlayerController? _activeController;
  Timer? _autoPlayTimer;
  StreamSubscription? _videoEndSubscription;
  var _isInitializing = false;
  var _userInteracted = false;
  var _visibleVideosCount = 3;
  double _lastScreenWidth = 0;

  @override
  void initState() {
    super.initState();

    _currentIndex$ = BehaviorSubject.seeded(0);
    _muted$ = BehaviorSubject.seeded(false);
    _isPlaying$ = BehaviorSubject.seeded(false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePageController();
      _initializeCurrentVideo();
    });
  }

  void _initializePageController() {
    final screenWidth = MediaQuery.of(context).size.width;
    _updateLayoutForScreenSize(screenWidth);

    _pageController = PageController(
      viewportFraction: _calculateViewportFraction(screenWidth),
    );

    // Trigger a rebuild after initialization
    if (mounted) {
      setState(() {});
    }
  }

  void _updateLayoutForScreenSize(double screenWidth) {
    if ((screenWidth - _lastScreenWidth).abs() < 50) {
      return; // Avoid frequent updates
    }

    const videoWidth = FixedVideoContainer.videoWidth;
    const spacing = FixedVideoContainer.spacing * 2;

    // Calculate how many videos can fit with padding
    var maxVideos = ((screenWidth - 60) / (videoWidth + spacing))
        .floor(); // 60 for safe margins
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

  Future<void> _initializeCurrentVideo() async {
    if (_isInitializing || widget.videos.isEmpty) return;

    _isInitializing = true;
    final currentIndex = _currentIndex$.value;

    try {
      await _disposeActiveController();

      final video = widget.videos[currentIndex];
      final controller = VideoPlayerController.network(video.url);

      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }

      _activeController = controller;
      controller.setLooping(false);
      controller.setVolume(_muted$.value ? 0 : 1);

      _videoEndSubscription?.cancel();
      _videoEndSubscription = controller.addListener(() {
        final value = controller.value;
        if (value.position >= value.duration &&
            value.duration > Duration.zero &&
            value.position > Duration.zero &&
            !value.isBuffering) {
          _onVideoEnded();
        }
      }) as StreamSubscription?;

      await controller.play();
      _isPlaying$.add(true);

      setState(() {});
    } catch (e) {
      debugPrint('Error initializing video: $e');
      _moveToNextVideo();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _disposeActiveController() async {
    _videoEndSubscription?.cancel();
    _videoEndSubscription = null;

    if (_activeController != null) {
      await _activeController!.pause();
      _activeController!.dispose();
      _activeController = null;
    }
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

  void _onPageChanged(int index) {
    if (_currentIndex$.value == index) return;

    _currentIndex$.add(index);
    _isPlaying$.add(false);
    _userInteracted = false;
    _autoPlayTimer?.cancel();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _initializeCurrentVideo();
      }
    });
  }

  void _startAutoPlay() {
    if (_autoPlayTimer != null) return;

    _autoPlayTimer = Timer.periodic(widget.autoPlayDelay, (timer) {
      if (_activeController == null ||
          !_activeController!.value.isInitialized) {
        return;
      }

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
    if (_activeController == null) return;

    _userInteracted = true;
    _autoPlayTimer?.cancel();

    if (_activeController!.value.isPlaying) {
      _activeController!.pause();
      _isPlaying$.add(false);
    } else {
      _activeController!.play();
      _isPlaying$.add(true);
    }
  }

  void _toggleMute() {
    final muted = !_muted$.value;
    _muted$.add(muted);
    _activeController?.setVolume(muted ? 0 : 1);
  }

  void _enterFullscreen() {
    if (_activeController == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => FullscreenVideoOverlay(
        controller: _activeController!,
        isMuted: _muted$.value,
        onToggleMute: _toggleMute,
      ),
    );
  }

  void _onVideoTap(int index) {
    if (index == _currentIndex$.value) {
      _togglePlayPause();
    } else {
      _userInteracted = true;
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
    _disposeActiveController();
    _pageController?.dispose();
    _currentIndex$.close();
    _muted$.close();
    _isPlaying$.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const height = FixedVideoContainer.videoHeight + 20;

    // Show loading indicator if page controller is not initialized yet
    if (_pageController == null) {
      return const SizedBox(
        height: height,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Handle screen size changes
        final currentWidth = constraints.maxWidth;
        if ((currentWidth - _lastScreenWidth).abs() > 50) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _updateLayoutForScreenSize(currentWidth);

              // Recreate PageController with new viewport fraction
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
          });
        }

        return VisibilityDetector(
          key: const Key('video-carousel'),
          onVisibilityChanged: (info) {
            if (info.visibleFraction < 0.5) {
              _activeController?.pause();
              _isPlaying$.add(false);
            } else if (_activeController != null && !_userInteracted) {
              _activeController?.play();
              _isPlaying$.add(true);
            }
          },
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
                  itemBuilder: (context, index) {
                    final isMain = index == currentIndex;
                    final video = widget.videos[index];

                    return FixedVideoContainer(
                      isMain: isMain,
                      child: GestureDetector(
                        onTap: () => _onVideoTap(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Video or thumbnail - ALWAYS fills the container completely
                              Positioned.fill(
                                child: isMain &&
                                        _activeController != null &&
                                        _activeController!.value.isInitialized
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _activeController!
                                              .value.size.width,
                                          height: _activeController!
                                              .value.size.height,
                                          child:
                                              VideoPlayer(_activeController!),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image:
                                                NetworkImage(video.thumbnail),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                              ),

                              // Play/Pause overlay - centered
                              if (isMain)
                                Positioned.fill(
                                  child: StreamBuilder<bool>(
                                    stream: _isPlaying$,
                                    builder: (context, snapshot) {
                                      final isPlaying = snapshot.data ?? false;
                                      return Center(
                                        child: VideoPlayPauseOverlay(
                                          isVisible: !isPlaying,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              // Fullscreen control - ALWAYS top-left corner
                              if (isMain)
                                VideoFullscreenControl(
                                  onFullscreen: _enterFullscreen,
                                ),

                              // Sound control - ALWAYS top-right corner
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

                              // Loading indicator
                              if (isMain && _isInitializing)
                                const Positioned.fill(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// Facebook-style fullscreen video overlay
class FullscreenVideoOverlay extends StatefulWidget {
  const FullscreenVideoOverlay({
    super.key,
    required this.controller,
    required this.isMuted,
    required this.onToggleMute,
  });
  final VideoPlayerController controller;
  final bool isMuted;
  final VoidCallback onToggleMute;

  @override
  State<FullscreenVideoOverlay> createState() => _FullscreenVideoOverlayState();
}

class _FullscreenVideoOverlayState extends State<FullscreenVideoOverlay>
    with SingleTickerProviderStateMixin {
  var _showControls = true;
  Timer? _hideControlsTimer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _closeFullscreen() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Center(
                child: GestureDetector(
                  onTap: _toggleControls,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: AspectRatio(
                      aspectRatio: widget.controller.value.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            // Video player
                            Positioned.fill(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: widget.controller.value.size.width,
                                  height: widget.controller.value.size.height,
                                  child: VideoPlayer(widget.controller),
                                ),
                              ),
                            ),

                            // Controls overlay
                            if (_showControls)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                    stops: const [0.0, 0.3, 0.7, 1.0],
                                  ),
                                ),
                              ),

                            // Close button
                            if (_showControls)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: _closeFullscreen,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),

                            // Sound control
                            if (_showControls)
                              Positioned(
                                top: 16,
                                left: 16,
                                child: GestureDetector(
                                  onTap: widget.onToggleMute,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Icon(
                                      widget.isMuted
                                          ? Icons.volume_off
                                          : Icons.volume_up,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
// // ignore_for_file: use_build_context_synchronously
//
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:rxdart/rxdart.dart';
// import 'package:visibility_detector/visibility_detector.dart';
//
// class VideoItem {
//   final String url;
//   final String thumbnail;
//
//   const VideoItem({required this.url, required this.thumbnail});
// }
//
// class VideoCarouselSection extends StatefulWidget {
//   final List<VideoItem> videos;
//
//   const VideoCarouselSection({super.key, required this.videos});
//
//   @override
//   State<VideoCarouselSection> createState() => _VideoCarouselSectionState();
// }
//
// class _VideoCarouselSectionState extends State<VideoCarouselSection> {
//   late final PageController _pageController;
//   late final List<VideoPlayerController?> _videoControllers;
//   late final BehaviorSubject<int> _currentIndex$;
//   late final BehaviorSubject<bool> _muted$;
//   late final BehaviorSubject<bool> _paused$;
//
//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(viewportFraction: 0.7);
//     _videoControllers = List.generate(widget.videos.length, (_) => null);
//     _currentIndex$ = BehaviorSubject.seeded(0);
//     _muted$ = BehaviorSubject.seeded(false);
//     _paused$ = BehaviorSubject.seeded(false);
//     _initVideoController(0);
//   }
//
//   Future<void> _initVideoController(int index) async {
//     _disposeVideoController(index);
//     final video = widget.videos[index];
//     final controller = VideoPlayerController.network(video.url);
//     await controller.initialize();
//     controller.setLooping(true);
//     controller.setVolume(_muted$.value ? 0 : 1);
//     controller.addListener(() {
//       if (controller.value.position >= controller.value.duration) {
//         _onVideoEnded(index);
//       }
//     });
//     if (!_paused$.value) controller.play();
//     _videoControllers[index] = controller;
//     setState(() {});
//   }
//
//   void _disposeVideoController(int index) {
//     _videoControllers[index]?.dispose();
//     _videoControllers[index] = null;
//   }
//
//   void _onPageChanged(int index) async {
//     final oldIndex = _currentIndex$.value;
//     _currentIndex$.add(index);
//     _videoControllers[oldIndex]?.pause();
//     _paused$.add(false);
//     await _initVideoController(index);
//   }
//
//   void _onVideoEnded(int index) {
//     _disposeVideoController(index);
//     final nextIndex = (index + 1) % widget.videos.length;
//     _pageController.animateToPage(nextIndex,
//         duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
//     _onPageChanged(nextIndex);
//   }
//
//   void _togglePlayPause(int index) {
//     final controller = _videoControllers[index];
//     if (controller == null) return;
//     if (controller.value.isPlaying) {
//       controller.pause();
//       _paused$.add(true);
//     } else {
//       controller.play();
//       _paused$.add(false);
//     }
//   }
//   // ensure other videos are paused when the page changes
//   void _ensureOtherVideosPaused(int index) {
//     for (var i = 0; i < _videoControllers.length; i++) {
//       if (i != index && _videoControllers[i] != null) {
//         _videoControllers[i]?.pause();
//       }
//     }
//   }
//
//   void _toggleMute() {
//     final muted = !_muted$.value;
//     _muted$.add(muted);
//     for (var controller in _videoControllers) {
//       controller?.setVolume(muted ? 0 : 1);
//     }
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     for (var c in _videoControllers) {
//       c?.dispose();
//     }
//     _currentIndex$.close();
//     _muted$.close();
//     _paused$.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final height = MediaQuery.of(context).size.height * 0.9;
//     final width = MediaQuery.of(context).size.width * 0.6;
//
//     return SizedBox(
//       height: height,
//       child: StreamBuilder<int>(
//         stream: _currentIndex$,
//         builder: (context, snapshot) {
//           final currentIndex = snapshot.data ?? 0;
//           return PageView.builder(
//             controller: _pageController,
//             onPageChanged: _onPageChanged,
//             itemCount: widget.videos.length,
//             physics: const BouncingScrollPhysics(),
//             itemBuilder: (context, index) {
//               final isMain = index == currentIndex;
//               final controller = _videoControllers[index];
//               final aspectRatio = controller?.value.aspectRatio ?? 9 / 16;
//               // Ensure other videos are paused when the main video is playing
//               if (isMain) {
//                 _ensureOtherVideosPaused(index);
//               }
//               return Center(
//                 child: Container(
//                   padding: EdgeInsets.symmetric(horizontal: isMain ? 12 : 24),
//                   width: aspectRatio < 1 ? width * 1 : width * 0.6,
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       AspectRatio(
//                         aspectRatio: aspectRatio,
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: controller != null && controller.value.isInitialized
//                               ? VideoPlayer(controller)
//                               : Image.network(
//                             widget.videos[index].thumbnail,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       if (isMain)
//                         StreamBuilder<bool>(
//                           stream: _paused$,
//                           builder: (context, snapshot) {
//                             final paused = snapshot.data ?? false;
//                             return AnimatedOpacity(
//                               opacity: paused ? 1 : 0,
//                               duration: const Duration(milliseconds: 200),
//                               child: Icon(Icons.play_circle_fill,
//                                   size: 80, color: Colors.white.withOpacity(0.8)),
//                             );
//                           },
//                         ),
//                       Positioned.fill(
//                         child: GestureDetector(
//                           onTap: () {
//                             if (isMain) {
//                               _togglePlayPause(index);
//                             } else {
//                               _pageController.animateToPage(index,
//                                   duration: const Duration(milliseconds: 400),
//                                   curve: Curves.easeInOut);
//                             }
//                           },
//                         ),
//                       ),
//                       if (isMain)
//                         Positioned(
//                           top: 16,
//                           right: 16,
//                           child: StreamBuilder<bool>(
//                             stream: _muted$,
//                             builder: (context, snapshot) {
//                               final muted = snapshot.data ?? false;
//                               return IconButton(
//                                 icon: Icon(
//                                   muted ? Icons.volume_off : Icons.volume_up,
//                                   color: Colors.white,
//                                   size: 28,
//                                 ),
//                                 onPressed: _toggleMute,
//                               );
//                             },
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
