// import 'package:flutter/material.dart';
// import 'package:flutter_landing_page/section/section.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
//
// // This file uses Riverpod code generation.
// // To generate the missing part file, run:
// // flutter pub run build_runner build --delete-conflicting-outputs
// part 'section_controller.g.dart';
//
// @Riverpod(keepAlive: true)
// class SectionController extends _$SectionController {
//   final Map<Section, GlobalKey> _sectionKeys = {};
//   ScrollController? _scrollController;
//
//   @override
//   Map<Section, GlobalKey> build() => {};
//
//   void setScrollController(ScrollController controller) {
//     _scrollController = controller;
//   }
//
//   void registerSection(Section section, GlobalKey key) {
//     _sectionKeys[section] = key;
//     state = Map.from(_sectionKeys);
//   }
//
//   void unregisterSection(Section section) {
//     _sectionKeys.remove(section);
//     state = Map.from(_sectionKeys);
//   }
//
//   Future<void> scrollToSection(Section section, {double offset = 0.0}) async {
//     final key = _sectionKeys[section];
//     final controller = _scrollController;
//
//     if (key?.currentContext == null || controller == null) {
//       return;
//     }
//
//     try {
//       await Scrollable.ensureVisible(
//         key!.currentContext!,
//         duration: const Duration(milliseconds: 700),
//         curve: Curves.easeInOut,
//         alignment: 0.0, // Top alignment
//         alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
//       );
//     } catch (e) {
//       // Fallback to manual scroll if ensureVisible fails
//       _scrollToSectionFallback(section, offset);
//     }
//   }
//
//   void _scrollToSectionFallback(Section section, double offset) {
//     final key = _sectionKeys[section];
//     final controller = _scrollController;
//
//     if (key?.currentContext == null || controller == null) {
//       return;
//     }
//
//     final renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
//     if (renderBox == null) return;
//
//     final position = renderBox.localToGlobal(Offset.zero).dy;
//     final scrollPosition = position - offset;
//
//     controller.animateTo(
//       scrollPosition.clamp(0.0, controller.position.maxScrollExtent),
//       duration: const Duration(milliseconds: 700),
//       curve: Curves.easeInOut,
//     );
//   }
//
//   void scrollToTop() {
//     _scrollController?.animateTo(
//       0.0,
//       duration: const Duration(milliseconds: 700),
//       curve: Curves.easeInOut,
//     );
//   }
//
//   bool isSectionRegistered(Section section) =>
//       _sectionKeys.containsKey(section);
// }
