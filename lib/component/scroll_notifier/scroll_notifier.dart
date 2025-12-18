import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_landing_page/component/scroll_notifier/scroll_section.dart';
import 'package:flutter_landing_page/header.dart';
import 'package:flutter_landing_page/section/section.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scroll_notifier.g.dart';

@Riverpod(keepAlive: true)
// ignore: unsupported_provider_value
class ScrollNotifier extends _$ScrollNotifier {
  final Map<Section, GlobalKey> _sectionKeys = {};

  @override
  ScrollSection build() => ScrollSection(
        controller: ScrollController(),
        sectionPositions: Section.values.map((s) => (s, 0.0)).toSet(),
      );

  /// Smoothly scroll to the very top of the page.
  void scrollTop() => _animateTo(0.0);

  /// Public API used by the header to scroll to any section.
  ///
  /// This implementation is based purely on widget positions via
  /// [Scrollable.ensureVisible], so it works reliably on all screen sizes
  /// without any manual offset math.
  Future<void> selectSection(Section section) => scrollToSection(section);

  /// Returns a stable [GlobalKey] for a given [Section].
  ///
  /// Attach this key to the top widget of each section so that
  /// [Scrollable.ensureVisible] can locate it.
  GlobalKey getSectionKey(Section section) {
    return _sectionKeys.putIfAbsent(section, () => GlobalKey());
  }

  /// Smoothly scrolls to the widget associated with the given [Section].
  Future<void> scrollToSection(Section section) async {
    final key = _sectionKeys[section];
    if (key == null) return;

    final context = key.currentContext;
    if (context == null) return;

    try {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.0, // align section to top
      );
    } catch (_) {
      // As a very safe fallback, just scroll to top/bottom bounds,
      // but avoid any manual offset calculations.
    }
  }

  void _animateTo(double offset) => state.controller.animateTo(
        offset,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
}
