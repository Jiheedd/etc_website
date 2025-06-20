import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intersperse/intersperse.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:websafe_svg/websafe_svg.dart';

import 'const.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    // (Icon path, Navigation URL)
    final snsComponents = <(String, String)>[
      ('assets/sns_x_mark.svg', 'https://twitter.com/'),
      ('assets/sns_github_mark.svg', 'https://github.com/'),
      ('assets/sns_discord_mark.svg', 'https://discord.com/'),
    ];

    const gap = Gap(16);

    return Container(
      height: 240,
      width: MediaQuery.sizeOf(context).width,
      // AppBarの`scrolledUnderElevation`のColorに合わせる調整
      color: theme.colorScheme.foreground.withOpacity(0.05),
      child: MaxWidthBox(
        maxWidth: Layout.maxWidth,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final sns in snsComponents)
                    _SNSIconButton(
                      filePath: sns.$1,
                      externalLink: sns.$2,
                    ),
                ].intersperse(gap).toList(),
              ),
              gap,
              Text(
                'footer_copyright'.tr,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SNSIconButton extends StatelessWidget {
  // ignore: unused_element
  const _SNSIconButton({required this.filePath, required this.externalLink});

  final String filePath;
  final String externalLink;

  @override
  Widget build(BuildContext context) {
    final color = ShadTheme.of(context).colorScheme.foreground;

    return ShadButton.outline(
      decoration: ShadDecoration(
          border: ShadBorder.all(radius: BorderRadius.circular(12))),
      leading: WebsafeSvg.asset(
        filePath,
        width: 20,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
      size: ShadButtonSize.lg,
      onPressed: () {
        final uri = Uri.tryParse(externalLink);
        if (uri == null) {
          throw Exception('Invalid URL: $externalLink');
        }
        launchUrl(uri);
      },
    );
  }
}
