import 'package:flutter/material.dart';
import 'package:flutter_landing_page/component/component.dart';
import 'package:flutter_landing_page/features/home/components/gallery_slider.dart';
import 'package:flutter_landing_page/section/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';

class GallerySection extends ConsumerWidget {
  const GallerySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final offset = box.localToGlobal(Offset.zero).dy;
            ref.read(scrollNotifierProvider.notifier).updateSectionPosition(
                  section: Section.gallery,
                  dy: offset,
                );
          }
        });

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
              GallerySlider(
                height: isLargeScreen ? 400 : 300,
                itemWidth: isLargeScreen ? 400 : 300,
                items: const [
                  GalleryItem(
                    imagePath: 'assets/images/gallery1.png',
                    title: 'gallery_item1',
                  ),
                  GalleryItem(
                    imagePath: 'assets/images/gallery2.png',
                    title: 'gallery_item2',
                  ),
                  GalleryItem(
                    imagePath: 'assets/images/gallery3.png',
                    title: 'gallery_item3',
                  ),
                  GalleryItem(
                    imagePath: 'assets/images/gallery4.png',
                    title: 'gallery_item4',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
