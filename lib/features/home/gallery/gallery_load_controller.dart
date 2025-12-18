import 'package:flutter/foundation.dart';

/// State for a single gallery image during sequential loading.
@immutable
class GalleryImageState {
  const GalleryImageState({
    required this.url,
    this.isLoaded = false,
    this.hasError = false,
  });

  final String url;
  final bool isLoaded;
  final bool hasError;

  GalleryImageState copyWith({
    String? url,
    bool? isLoaded,
    bool? hasError,
  }) {
    return GalleryImageState(
      url: url ?? this.url,
      isLoaded: isLoaded ?? this.isLoaded,
      hasError: hasError ?? this.hasError,
    );
  }
}

/// Controller that manages sequential (one-by-one) image loading.
///
/// Ensures only one image downloads at a time to prevent:
/// - Network congestion
/// - Memory spikes
/// - Missing images
/// - UI jank
///
/// Works with cached images - if an image is already cached,
/// it loads instantly and moves to the next immediately.
class GalleryLoadController extends ChangeNotifier {
  GalleryLoadController();

  final List<GalleryImageState> _images = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  /// Current list of image states (read-only).
  List<GalleryImageState> get images => List.unmodifiable(_images);

  /// Index of the image currently being loaded (or -1 if none).
  int get currentIndex => _currentIndex < _images.length ? _currentIndex : -1;

  /// Whether any image is currently loading.
  bool get isLoading => _isLoading && _currentIndex < _images.length;

  /// Whether all images have finished loading (success or error).
  bool get isComplete => _currentIndex >= _images.length;

  /// Sets the list of URLs to load sequentially.
  ///
  /// Resets state and starts loading from the first image.
  void setImages(List<String> urls) {
    _images.clear();
    _images.addAll(urls.map((url) => GalleryImageState(url: url)));
    _currentIndex = 0;
    _isLoading = false;
    notifyListeners();
    _loadNext();
  }

  /// Adds more URLs to the queue without resetting.
  ///
  /// If loading is complete, starts loading the new images.
  void addImages(List<String> urls) {
    final startIndex = _images.length;
    _images.addAll(urls.map((url) => GalleryImageState(url: url)));
    notifyListeners();

    // If we were done, resume loading from the new images.
    if (_currentIndex >= startIndex) {
      _loadNext();
    }
  }

  /// Starts loading the next image in sequence.
  void _loadNext() {
    if (_isLoading) return;
    if (_currentIndex >= _images.length) return;

    _isLoading = true;
    notifyListeners();
  }

  /// Marks the current image as successfully loaded.
  ///
  /// Moves to the next image automatically.
  void markLoaded() {
    if (_currentIndex >= _images.length) return;

    _images[_currentIndex] = _images[_currentIndex].copyWith(
      isLoaded: true,
      hasError: false,
    );
    _currentIndex++;
    _isLoading = false;
    notifyListeners();
    _loadNext();
  }

  /// Marks the current image as failed.
  ///
  /// Moves to the next image automatically (does not retry).
  void markFailed() {
    if (_currentIndex >= _images.length) return;

    _images[_currentIndex] = _images[_currentIndex].copyWith(
      isLoaded: false,
      hasError: true,
    );
    _currentIndex++;
    _isLoading = false;
    notifyListeners();
    _loadNext();
  }

  /// Checks if an image at [index] should attempt loading.
  ///
  /// Returns true only if:
  /// - It's the current image being loaded, OR
  /// - It's already been loaded (cached images load instantly)
  bool shouldLoad(int index) {
    if (index < 0 || index >= _images.length) return false;
    final image = _images[index];
    return index == _currentIndex || image.isLoaded;
  }

  /// Gets the state for an image at [index].
  GalleryImageState? getImageState(int index) {
    if (index < 0 || index >= _images.length) return null;
    return _images[index];
  }
}

