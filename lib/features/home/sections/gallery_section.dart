import 'package:flutter/material.dart';
import 'package:flutter_landing_page/component/component.dart';
import 'package:flutter_landing_page/features/home/components/gallery_slider.dart';
import 'package:flutter_landing_page/features/home/gallery/expandable_gallery_controller.dart';
import 'package:flutter_landing_page/features/home/gallery/gallery_load_controller.dart';
import 'package:flutter_landing_page/features/home/widgets/gallery_overlay.dart';
import 'package:flutter_landing_page/section/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

class GallerySection extends ConsumerStatefulWidget {
  const GallerySection({super.key});

  @override
  ConsumerState<GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends ConsumerState<GallerySection> {
  bool _visibilityTriggered = false;
  int _lastNeededCount = 0;
  final GalleryLoadController _loadController = GalleryLoadController();

  @override
  void dispose() {
    _loadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final galleryState = ref.watch(expandableGalleryControllerProvider);
    final galleryController =
    ref.read(expandableGalleryControllerProvider.notifier);

    return Container(
      key: const ValueKey(Section.gallery),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: Theme.of(context).colorScheme.surface,
      child: VisibilityDetector(
        key: const Key('gallery-section-visibility'),
        onVisibilityChanged: (info) {
          if (!_visibilityTriggered &&
              info.visibleFraction > 0.1 &&
              _lastNeededCount > 0 &&
              !galleryState.isLoading &&
              galleryState.urls.length < _lastNeededCount) {
            _visibilityTriggered = true;
            galleryController.loadInitialRow(_lastNeededCount);
          }
        },
        child: Column(
          children: [
            Text(
              'gallery_title'.tr,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 40),

            /// =======================
            /// CENTERED GALLERY LOGIC
            /// =======================
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = isLargeScreen ? 350.0 : 300.0;
                const spacing = 12.0;

                final visibleCount =
                ((constraints.maxWidth + spacing) /
                    (itemWidth + spacing))
                    .floor()
                    .clamp(1, 12);

                _lastNeededCount = visibleCount;

                final urls =
                galleryState.urls.take(visibleCount).toList();
                final galleryHeight = isLargeScreen ? 350.0 : 300.0;

                // Initialize sequential loader when URLs arrive.
                if (urls.isNotEmpty && _loadController.images.isEmpty) {
                  Future.microtask(() {
                    _loadController.setImages(urls);
                  });
                }

                if (urls.isEmpty) {
                  return SizedBox(
                    height: galleryHeight,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                /// Exact width needed by items → forces centering
                final totalWidth = (urls.length * itemWidth) +
                    ((urls.length - 1) * spacing);

                return Center(
                  child: SizedBox(
                    width: totalWidth,
                    child: GallerySlider.sequential(
                      height: galleryHeight,
                      itemWidth: itemWidth,
                      itemSpacing: spacing,
                      urls: urls,
                      loadController: _loadController,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            Center(
              child: ShadButton.outline(
                onPressed: () => showGalleryOverlay(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('see_more'.tr),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
