import 'package:flutter/material.dart';
import 'package:flutter_landing_page/component/component.dart';
import 'package:flutter_landing_page/features/home/components/gallery_slider.dart';
import 'package:flutter_landing_page/features/home/gallery/expandable_gallery_controller.dart';
import 'package:flutter_landing_page/features/home/widgets/gallery_overlay.dart';
import 'package:flutter_landing_page/section/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class GallerySection extends ConsumerWidget {
  const GallerySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    final galleryState = ref.watch(expandableGalleryControllerProvider);
    final galleryController =
        ref.read(expandableGalleryControllerProvider.notifier);

    return Container(
      key: const ValueKey(Section.gallery),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: Theme.of(context).colorScheme.surface,
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
          LayoutBuilder(builder: (context, constraints) {
            // Collapsed mode rule: load ONLY enough images to fill one visible row.
            final itemWidth = isLargeScreen ? 400.0 : 300.0;
            const spacing = 12.0;
            final visibleCount =
                ((constraints.maxWidth + spacing) / (itemWidth + spacing))
                    .floor()
                    .clamp(1, 12);

            if (!galleryState.isLoading &&
                galleryState.urls.length < visibleCount) {
              // One-row request; no prefetch beyond this.
              Future.microtask(() => galleryController.loadInitialRow(visibleCount));
            }

            final urls = galleryState.urls.take(visibleCount).toList();
            final items =
                urls.map((u) => GalleryItem.network(networkUrl: u)).toList();

            return GallerySlider(
              height: isLargeScreen ? 400 : 300,
              itemWidth: itemWidth,
              itemSpacing: spacing,
              items: items,
            );
          }),
          const SizedBox(height: 12),
          Center(
            child: ShadButton.outline(
              onPressed: () => showGalleryOverlay(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('see_more'.tr),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
