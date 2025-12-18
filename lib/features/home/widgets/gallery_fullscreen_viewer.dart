import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'progressive_network_image.dart';

Future<void> showGalleryFullscreenViewer(
  BuildContext context, {
  required List<String> urls,
  required int initialIndex,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'gallery-fullscreen',
    barrierColor: Colors.black.withOpacity(0.65),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, __) {
      return _GalleryFullscreenViewer(urls: urls, initialIndex: initialIndex);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: child,
      );
    },
  );
}

class _GalleryFullscreenViewer extends StatefulWidget {
  const _GalleryFullscreenViewer({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_GalleryFullscreenViewer> createState() => _GalleryFullscreenViewerState();
}

class _GalleryFullscreenViewerState extends State<_GalleryFullscreenViewer> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  void _navigateTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final zoneWidth = screenWidth > 600 ? 100.0 : 60.0;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                // Click-outside to close fullscreen (overlay remains underneath).
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned.fill(
                  child: Stack(
                    children: [
                      Center(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: widget.urls.length,
                          itemBuilder: (context, index) {
                            return InteractiveViewer(
                              minScale: 1,
                              maxScale: 3,
                              child: ProgressiveNetworkImage(
                                url: widget.urls[index],
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        ),
                      ),
                      if (_currentIndex > 0)
                        _NavArrow(
                          isLeft: true,
                          width: zoneWidth,
                          onTap: () => _navigateTo(_currentIndex - 1),
                        ),
                      if (_currentIndex < widget.urls.length - 1)
                        _NavArrow(
                          isLeft: false,
                          width: zoneWidth,
                          onTap: () => _navigateTo(_currentIndex + 1),
                        ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 32),
                          padding: const EdgeInsets.all(16),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.isLeft,
    required this.onTap,
    required this.width,
  });

  final bool isLeft;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: Container(
            width: width,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                colors: [Colors.black.withOpacity(0.35), Colors.transparent],
              ),
            ),
            child: Icon(
              isLeft ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}


