import 'package:flutter/material.dart';
import 'package:flutter_landing_page/const.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gallery/expandable_gallery_controller.dart';
import '../widgets/progressive_network_image.dart';
import '../widgets/gallery_overlay.dart';

/// A preview grid + expand button placed under the existing gallery slider.
///
/// Clicking the arrow opens a scrollable overlay (dialog) that lazy-loads
/// images from Firebase Storage in batches.
class ExpandableGallerySection extends ConsumerWidget {
  const ExpandableGallerySection({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expandableGalleryControllerProvider);
    final controller = ref.read(expandableGalleryControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _CollapsedOneRow(
          urls: state.urls,
          isLoading: state.isLoading,
          onNeedCount: controller.loadInitialRow,
        ),
        const SizedBox(height: 12),
        Center(
          child: IconButton(
            tooltip: 'Voir plus',
            iconSize: 40,
            onPressed: () {
              showGalleryOverlay(context);
            },
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ),
      ],
    );
  }
}

class _CollapsedOneRow extends StatelessWidget {
  const _CollapsedOneRow({
    required this.urls,
    required this.isLoading,
    required this.onNeedCount,
  });

  final List<String> urls;
  final bool isLoading;
  final Future<void> Function(int count) onNeedCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Layout.maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Collapsed mode rule: show ONLY 1 row, and load ONLY enough to fill 1 row.
            const spacing = 12.0;
            final cols = _columnsForWidth(constraints.maxWidth);
            final needCount = cols;

            // Request exactly one row worth, no prefetch.
            if (urls.length < needCount && !isLoading) {
              Future.microtask(() => onNeedCount(needCount));
            }

            final tileWidth =
                (constraints.maxWidth - (spacing * (cols - 1))) / cols;
            final tileHeight = tileWidth; // square tiles for predictable 1-row height

            if (urls.isEmpty && isLoading) {
              return SizedBox(
                height: tileHeight,
                child: Row(
                  children: List.generate(
                    cols,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == cols - 1 ? 0 : spacing),
                        child: _SkeletonTile(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              );
            }

            if (urls.isEmpty) {
              return const _EmptyPreview();
            }

            final visible = urls.take(needCount).toList();
            return SizedBox(
              height: tileHeight,
              child: Row(
                children: List.generate(
                  cols,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == cols - 1 ? 0 : spacing),
                      child: ProgressiveNetworkImage(
                        url: visible[i],
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _columnsForWidth(double width) {
    if (width >= 1100) return 6;
    if (width >= 800) return 5;
    if (width >= 600) return 4;
    return 3;
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(
        'Aucune photo disponible pour le moment.',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TilePlaceholder extends StatelessWidget {
  const _TilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _TileError extends StatelessWidget {
  const _TileError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined),
    );
  }
}

class _ShimmerGridPlaceholder extends StatefulWidget {
  const _ShimmerGridPlaceholder({
    required this.columns,
    required this.itemCount,
  });

  final int columns;
  final int itemCount;

  @override
  State<_ShimmerGridPlaceholder> createState() => _ShimmerGridPlaceholderState();
}

class _ShimmerGridPlaceholderState extends State<_ShimmerGridPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25);
    final highlight = Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.45);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 4 / 3,
          ),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            final v = (t + (index / widget.itemCount)) % 1.0;
            final color = Color.lerp(base, highlight, (v - 0.5).abs() * 2) ?? base;
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(color: color),
            );
          },
        );
      },
    );
  }
}

class _SkeletonTile extends StatefulWidget {
  const _SkeletonTile({required this.borderRadius});
  final BorderRadius borderRadius;

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withOpacity(0.25);
    final highlight = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withOpacity(0.45);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final color = Color.lerp(base, highlight, (t - 0.5).abs() * 2) ?? base;
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: ColoredBox(color: color),
        );
      },
    );
  }
}


