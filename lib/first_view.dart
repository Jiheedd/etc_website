import 'package:flutter/material.dart';
import 'package:flutter_landing_page/const.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FirstView extends StatelessWidget {
  const FirstView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: MaxWidthBox(
        maxWidth: Layout.maxWidth,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'first_view_title'.tr,
                      textAlign: TextAlign.center,
                      style: ShadTheme.of(context).textTheme.h1Large.copyWith(
                            fontSize: 80,
                          ),
                    ),
                    const Gap(40),
                    ShadButton(
                      size: ShadButtonSize.lg,
                      onPressed: () {
                        showShadDialog<void>(
                          context: context,
                          builder: (context) => ShadDialog.alert(
                            title: Text('first_view_dialog_title'.tr),
                            child: Text(
                              'first_view_dialog_message'.tr,
                              style: ShadTheme.of(context).textTheme.p,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'first_view_button'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 80,
              child: RotatedBox(
                quarterTurns: 1,
                child: Icon(
                  Icons.navigate_next_outlined,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
