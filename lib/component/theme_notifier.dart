import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

part 'theme_notifier.g.dart';

@Riverpod(keepAlive: true)
// ignore: notifier_extends
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggleTheme() {
    // Flip between light and dark
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setTheme(ThemeMode mode) async => state = mode;
}


extension on ThemeMode {
  bool get isDark => this == ThemeMode.dark;
}

extension BrightnessX on Brightness {
  bool get isDark => this == Brightness.dark;
}

class ThemeSwitchButton extends ConsumerWidget {
  const ThemeSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ShadTheme.of(context).brightness;
    final themeMode = ref.watch(themeNotifierProvider) == ThemeMode.system
        ? brightness.isDark
            ? ThemeMode.dark
            : ThemeMode.light
        : ref.watch(themeNotifierProvider);

    return ShadButton.outline(
      leading: Icon(
        themeMode.isDark ? Icons.light_mode : Icons.dark_mode,
        size: 16,
      ),
      size: ShadButtonSize.regular,
      onPressed: () {
        ref.read(themeNotifierProvider.notifier).toggleTheme();
      },
    );
  }
}
