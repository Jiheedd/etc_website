import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../gallery/gallery_load_controller.dart';

/// Sequential image loader that loads images one-by-one.
///
/// Only attempts to load when [shouldLoad] is true (controlled by
/// [GalleryLoadController]). Uses [CachedNetworkImage] callbacks to notify
/// the controller when loading completes (success or error).
///
/// If the image is already cached, it loads instantly and the controller
/// immediately moves to the next image.
class SequentialNetworkImage extends StatelessWidget {
  const SequentialNetworkImage({
    super.key,
    required this.url,
    required this.index,
    required this.controller,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final int index;
  final GalleryLoadController controller;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageState = controller.getImageState(index);
    final shouldLoad = controller.shouldLoad(index);

    // If we shouldn't load yet and haven't loaded, show placeholder space.
    if (!shouldLoad && (imageState == null || !imageState.isLoaded)) {
      return _buildPlaceholderSpace(context);
    }

    // If it failed, show error but keep space reserved.
    if (imageState?.hasError ?? false) {
      return _buildErrorSpace(context);
    }

    // Attempt to load (either current index or already loaded).
    return CachedNetworkImage(
      key: ValueKey(url),
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, _) => _buildPlaceholderSpace(context),
      errorWidget: (context, _, __) {
        // Notify controller on error (using postFrameCallback to avoid rebuild loops).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.currentIndex == index) {
            controller.markFailed();
          }
        });
        return _buildErrorSpace(context);
      },
      imageBuilder: (context, imageProvider) {
        // Notify controller on success (using postFrameCallback to avoid rebuild loops).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.currentIndex == index) {
            controller.markLoaded();
          }
        });
        return Image(image: imageProvider, fit: fit);
      },
    );
  }

  Widget _buildPlaceholderSpace(BuildContext context) {
    final baseColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withOpacity(0.35);

    Widget content = Container(
      color: baseColor,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return content;
  }

  Widget _buildErrorSpace(BuildContext context) {
    final baseColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withOpacity(0.35);

    Widget content = Container(
      color: baseColor,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined),
    );

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return content;
  }
}

