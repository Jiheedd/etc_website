import 'package:flutter/material.dart';

/// Lightweight progressive image renderer for web/mobile.
///
/// - Uses `Image.network` (no per-item FutureBuilder)
/// - Uses `loadingBuilder` + `frameBuilder` to avoid layout shifts
/// - Fades-in when the first frame is available
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
    final placeholder = Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.35),
    );

    final image = Image.network(
      url,
      fit: fit,
      filterQuality: FilterQuality.low,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            const Center(child: Icon(Icons.broken_image_outlined)),
          ],
        );
      },
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}


