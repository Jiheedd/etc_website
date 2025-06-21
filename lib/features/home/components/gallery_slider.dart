// Full updated code with arrow zones and correct clickable behavior
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GallerySlider extends StatefulWidget {
  const GallerySlider({
    super.key,
    required this.items,
    this.height = 400,
    this.itemWidth = 300,
    this.itemSpacing = 12,
  });
  final List<GalleryItem> items;
  final double height;
  final double itemWidth;
  final double itemSpacing;

  @override
  State<GallerySlider> createState() => _GallerySliderState();
}

class _GallerySliderState extends State<GallerySlider> {
  late final PageController _pageController;
  var _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullscreen(int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => GalleryFullscreenView(
        items: widget.items,
        initialIndex: index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < widget.items.length - 1 ? widget.itemSpacing : 0,
            ),
            child: _GalleryItem(
              item: widget.items[index],
              width: widget.itemWidth,
              onTap: () => _openFullscreen(index),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryItem extends StatefulWidget {
  const _GalleryItem({
    required this.item,
    required this.width,
    required this.onTap,
  });
  final GalleryItem item;
  final double width;
  final VoidCallback onTap;

  @override
  State<_GalleryItem> createState() => _GalleryItemState();
}

class _GalleryItemState extends State<_GalleryItem> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  widget.item.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isHovered ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      widget.item.title.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryFullscreenView extends StatefulWidget {
  const GalleryFullscreenView({
    super.key,
    required this.items,
    required this.initialIndex,
  });
  final List<GalleryItem> items;
  final int initialIndex;

  @override
  State<GalleryFullscreenView> createState() => _GalleryFullscreenViewState();
}

class _GalleryFullscreenViewState extends State<GalleryFullscreenView> {
  late int _currentIndex;
  late final PageController _pageController;
  var _isRTL = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _isRTL = Get.locale?.languageCode == 'ar';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _navigateToImage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final zoneWidth = screenWidth > 600 ? 100.0 : 60.0;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Center(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 3,
                      child: Image.asset(
                        widget.items[index].imagePath,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
              if (_isRTL
                  ? _currentIndex < widget.items.length - 1
                  : _currentIndex > 0)
                _NavigationArrow(
                  isLeft: !_isRTL,
                  width: zoneWidth,
                  onTap: () =>
                      _navigateToImage(_currentIndex + (_isRTL ? 1 : -1)),
                ),
              if (_isRTL
                  ? _currentIndex > 0
                  : _currentIndex < widget.items.length - 1)
                _NavigationArrow(
                  isLeft: _isRTL,
                  width: zoneWidth,
                  onTap: () =>
                      _navigateToImage(_currentIndex + (_isRTL ? -1 : 1)),
                ),
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  padding: const EdgeInsets.all(16),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavigationArrow extends StatelessWidget {
  const _NavigationArrow({
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
                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
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

class GalleryItem {
  const GalleryItem({
    required this.imagePath,
    required this.title,
  });
  final String imagePath;
  final String title;
}
