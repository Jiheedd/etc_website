import 'package:flutter/material.dart';
import 'package:flutter_landing_page/component/component.dart';
import 'package:flutter_landing_page/core/controllers/language_controller.dart';
import 'package:flutter_landing_page/section/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:websafe_svg/websafe_svg.dart';

import 'const.dart';

class Header extends ConsumerWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final isDesktopLarger =
    //     ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return AppBar(
      backgroundColor: Colors.transparent,
      toolbarHeight: 80,
      title: MaxWidthBox(
        maxWidth: Layout.maxWidth,
        child: Row(
          children: [
            const _AppLogo(),
            const Spacer(),
            if (MediaQuery.of(context).size.width > 900) const _PageLinks(),
            const _LanguageSelector(),
            const ThemeSwitchButton(),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size(double.infinity, 80);

  static double get height => const Header().preferredSize.height;
}

class _AppLogo extends ConsumerWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoFile = ShadTheme.of(context).brightness.isDark
        ? 'assets/logo_dark.svg'
        : 'assets/logo_light.svg';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        child: WebsafeSvg.asset(logoFile, height: 32),
        // child: ShadTheme.of(context).brightness.isDark ? WebsafeSvg.asset(logoFile, height: 32) : Image.asset(logoFile, height: 100, width: 150,),
        // child: Image.asset(logoFile, height: 100, width: 150,),
        onTap: () {
          ref.read(scrollNotifierProvider.notifier).scrollTop();
        },
      ),
    );
  }
}

class _PageLinks extends ConsumerWidget {
  const _PageLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        for (final section in Section.values)
          ShadButton.link(
            child: Text(section.name.tr),
            onPressed: () {
              ref.read(scrollNotifierProvider.notifier).selectSection(section);
            },
          ),
      ],
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LanguageController>();

    return Obx(() => ShadButton.outline(
          leading: const Icon(Icons.language, size: 16),
          child: Text(controller.getLanguageName(controller.currentLanguage)),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('language'.tr),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('English'),
                      onTap: () {
                        controller.changeLanguage('en');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text('العربية'),
                      onTap: () {
                        controller.changeLanguage('ar');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text('Français'),
                      onTap: () {
                        controller.changeLanguage('fr');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ));
  }
}
