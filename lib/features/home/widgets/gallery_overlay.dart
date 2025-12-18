import 'package:flutter/material.dart';
import 'package:flutter_landing_page/const.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gallery/expandable_gallery_controller.dart';
import 'gallery_fullscreen_viewer.dart';
import 'progressive_network_image.dart';

/// Opens the expandable gallery overlay as a fullscreen-like dialog
/// while preserving page margins and allowing click-outside to dismiss.
Future<void> showGalleryOverlay(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'gallery-overlay',
    barrierColor: Colors.black.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, __) {
      return const _GalleryOverlay();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _GalleryOverlay extends ConsumerStatefulWidget {
  const _GalleryOverlay();

  @override
  ConsumerState<_GalleryOverlay> createState() => _GalleryOverlayState();
}

class _GalleryOverlayState extends ConsumerState<_GalleryOverlay> {
  final ScrollController _scrollController = ScrollController();
  var _requestedInitial = false;
  var _lastBatchSize = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger pagination when near the bottom.
    final position = _scrollController.position;
    if (!position.hasPixels || !position.hasContentDimensions) return;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref
          .read(expandableGalleryControllerProvider.notifier)
          .loadNextBatch(_lastBatchSize);
    }
  }

  int _columnsForWidth(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 650) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expandableGalleryControllerProvider);
    final controller = ref.read(expandableGalleryControllerProvider.notifier);

    return SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          // Keeps margins consistent with the rest of the page.
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Layout.maxWidth),
              child: GestureDetector(
                // Prevent taps inside the panel from dismissing the dialog.
                onTap: () {},
                child: _OverlayPanel(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = _columnsForWidth(constraints.maxWidth);
                      final batchSize = cols * 3; // 3 rows per batch (required)
                      _lastBatchSize = batchSize;

                      // First paint must be fast: request only 3 rows initially.
                      if (!_requestedInitial) {
                        _requestedInitial = true;
                        Future.microtask(() => controller.loadNextBatch(batchSize));
                      }

                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: _OverlayHeader(
                              onClose: () => Navigator.of(context).pop(),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.only(top: 12, bottom: 24),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 4 / 3,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >= state.urls.length) {
                                    return const _TilePlaceholder();
                                  }

                                  final url = state.urls[index];
                                  return _OverlayTile(
                                    url: url,
                                    onTap: () async {
                                      await showGalleryFullscreenViewer(
                                        context,
                                        urls: state.urls,
                                        initialIndex: index,
                                      );
                                    },
                                  );
                                },
                                childCount: state.urls.length +
                                    (state.isLoadingMore ? cols : 0),
                              ),
                            ),
                          ),
                          if (state.urls.isEmpty && state.isLoading)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          SliverToBoxAdapter(
                            child: _BottomStatus(
                              isLoadingMore: state.isLoadingMore,
                              hasMore: state.hasMore,
                              onRetry: () => controller.loadNextBatch(batchSize),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayPanel extends StatelessWidget {
  const _OverlayPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _OverlayHeader extends StatelessWidget {
  const _OverlayHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      child: Row(
        children: [
          Text(
            'Galerie',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Fermer',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _OverlayTile extends StatelessWidget {
  const _OverlayTile({required this.url, required this.onTap});
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ProgressiveNetworkImage(
            url: url,
            fit: BoxFit.cover,
          ),
        ),
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

class _BottomStatus extends StatelessWidget {
  const _BottomStatus({
    required this.isLoadingMore,
    required this.hasMore,
    required this.onRetry,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!hasMore) {
      return const SizedBox(height: 16);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: TextButton(
          onPressed: onRetry,
          child: const Text('Charger plus'),
        ),
      ),
    );
  }
}


