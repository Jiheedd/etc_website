import 'package:flutter/material.dart';
import 'package:flutter_landing_page/component/component.dart';
import 'package:flutter_landing_page/section/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';

class IntroSection extends ConsumerWidget {
  const IntroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRtl = Get.locale?.languageCode == 'ar';

    return Container(
      key: const ValueKey(Section.intro),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: ResponsiveRowColumn(
        rowMainAxisAlignment: MainAxisAlignment.center,
        columnMainAxisAlignment: MainAxisAlignment.center,
        layout: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
            ? ResponsiveRowColumnType.ROW
            : ResponsiveRowColumnType.COLUMN,
        children: [
          ResponsiveRowColumnItem(
            rowFlex: 1,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                    isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    'intro_title'.tr,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'intro_subtitle'.tr,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'intro_description'.tr,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
          ),
          ResponsiveRowColumnItem(
            rowFlex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Image.asset(
                'assets/images/gallery5.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
