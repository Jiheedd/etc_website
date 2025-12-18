import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Lightweight progressive image renderer for web/mobile.
///
/// - Uses `CachedNetworkImage` (web-safe, cached)
/// - Shows skeleton + small spinner while loading
/// - Fades in when the image is ready
class ProgressiveNetworkImage extends StatelessWidget {
  const ProgressiveNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withOpacity(0.35);

    Widget buildPlaceholder() => Container(
          color: baseColor,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );

    Widget buildError() => Container(
          color: baseColor,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        );

    final image = CachedNetworkImage(
      key: ValueKey(url),
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, _) => buildPlaceholder(),
      errorWidget: (context, _, __) => buildError(),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

