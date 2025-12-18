import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_storage_gallery_repository.dart';

final expandableGalleryRepositoryProvider =
    Provider<FirebaseStorageGalleryRepository>(
  (ref) => FirebaseStorageGalleryRepository(),
);

final expandableGalleryControllerProvider =
    StateNotifierProvider<ExpandableGalleryController, ExpandableGalleryState>(
  (ref) => ExpandableGalleryController(
    repo: ref.watch(expandableGalleryRepositoryProvider),
  ),
);

class ExpandableGalleryController extends StateNotifier<ExpandableGalleryState> {
  ExpandableGalleryController({required FirebaseStorageGalleryRepository repo})
      : _repo = repo,
        super(const ExpandableGalleryState());

  final FirebaseStorageGalleryRepository _repo;
  int? _lastPreviewTarget;

  /// Collapsed mode: load ONLY enough images to fill one row.
  Future<void> loadInitialRow(int targetCount) async {
    // Avoid repeated calls for the same layout width.
    if (_lastPreviewTarget == targetCount && state.urls.length >= targetCount) {
      return;
    }
    _lastPreviewTarget = targetCount;

    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    await _repo.loadUpTo(targetCount);
    if (!mounted) return;

    state = state.copyWith(
      isLoading: false,
      urls: _repo.cachedUrls,
      hasMore: _repo.hasMore,
    );
  }

  /// Expanded mode: load the next batch (e.g. 3 rows worth) progressively.
  Future<void> loadNextBatch(int batchSize) async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);

    await _repo.loadNextBatch(batchSize);
    if (!mounted) return;

    state = state.copyWith(
      isLoadingMore: false,
      urls: _repo.cachedUrls,
      hasMore: _repo.hasMore,
    );
  }
}

@immutable
class ExpandableGalleryState {
  const ExpandableGalleryState({
    this.urls = const <String>[],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<String> urls;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  ExpandableGalleryState copyWith({
    List<String>? urls,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) {
    return ExpandableGalleryState(
      urls: urls ?? this.urls,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}


