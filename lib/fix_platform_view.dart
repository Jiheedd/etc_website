// Compatibility shim for platformViewRegistry on web
// This file ensures platformViewRegistry from dart:ui_web is available
// for packages like youtube_player_iframe_web that may not properly import it

// Import dart:ui_web to ensure platformViewRegistry is available in the compilation unit
// This helps resolve compile-time errors in packages that reference platformViewRegistry
// without properly importing dart:ui_web
import 'dart:ui_web' as ui_web;

/// Ensures platformViewRegistry is available for web plugins
/// 
/// This function ensures dart:ui_web is loaded early in the compilation process,
/// which helps with packages like youtube_player_iframe_web 2.0.2 that reference
/// platformViewRegistry without properly importing dart:ui_web.
/// 
/// Note: This is a workaround for a bug in older versions of youtube_player_iframe_web.
/// Consider updating to a newer version of the package if available.
void ensurePlatformViewRegistry() {
  // Access platformViewRegistry to ensure dart:ui_web is included in compilation
  // This makes the symbol available to other compilation units that might reference it
  // without directly importing it
  try {
    // Force the symbol to be included in the compilation by referencing it
    // This helps resolve undefined name errors in packages that use it incorrectly
    final _ = ui_web.platformViewRegistry;
    // The registry is now available in the compilation unit
  } catch (e) {
    // This should not happen on web platforms, but handle gracefully
    // The registry should be available at runtime even if there's a compile-time issue
    assert(false, 'platformViewRegistry initialization check failed: $e');
  }
}

