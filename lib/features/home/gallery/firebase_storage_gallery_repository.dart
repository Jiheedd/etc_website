import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Loads image URLs from Firebase Storage using a paginated approach.
///
/// IMPORTANT (Flutter Web):
/// - Accessing Firebase services before Firebase is initialized can throw
///   JS interop TypeErrors.
/// - Always guard with `Firebase.apps.isNotEmpty` before calling Storage.
class FirebaseStorageGalleryRepository {
  FirebaseStorageGalleryRepository({
    FirebaseStorage? storage,
    this.galleryPath = 'gallery',
  }) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  final String galleryPath;

  // In-memory cache for the current session (prevents re-fetching URLs).
  final List<String> _cachedUrls = <String>[];
  String? _nextPageToken;
  bool _hasMore = true;
  Future<void>? _inFlight;

  List<String> get cachedUrls => List.unmodifiable(_cachedUrls);
  bool get hasMore => _hasMore;

  /// Loads enough images to reach [targetCount] in the in-memory cache.
  ///
  /// - Uses Firebase Storage `gallery/` ONLY (no subfolders for this feature).
  /// - Uses `list()` pagination via `pageToken`.
  /// - Prevents duplicate requests via a single in-flight guard.
  /// - Safe on Flutter Web when Firebase isn't initialized.
  Future<void> loadUpTo(int targetCount) async {
    if (_cachedUrls.length >= targetCount) return;
    if (!_hasMore) return;

    _inFlight ??= _loadUntil(targetCount);
    try {
      await _inFlight;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> loadNextBatch(int batchSize) async {
    if (!_hasMore) return;

    _inFlight ??= _loadUntil(_cachedUrls.length + batchSize);
    try {
      await _inFlight;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _loadUntil(int targetCount) async {
    // Flutter Web safety: do not touch Firebase services if not initialized.
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[FirebaseStorageGalleryRepository] Firebase not initialized. '
          'Skipping Storage fetch for "$galleryPath/".',
        );
      }
      _hasMore = false;
      return;
    }

    while (_cachedUrls.length < targetCount && _hasMore) {
      final toFetch = (targetCount - _cachedUrls.length).clamp(1, 60);
      try {
        final ref = _storage.ref(galleryPath);
        final result = await ref.list(
          ListOptions(
            maxResults: toFetch,
            pageToken: _nextPageToken,
          ),
        );

        // Note: `list()` returns both `items` (files) and `prefixes` (folders).
        // For this feature we only use files directly under `/gallery/`.
        final urls = await Future.wait(
          result.items.map((item) => item.getDownloadURL()),
        );

        _cachedUrls.addAll(urls);
        _nextPageToken = result.nextPageToken;
        _hasMore = _nextPageToken != null;
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('[FirebaseStorageGalleryRepository] Storage list error: $e');
          debugPrint(stack.toString());
        }
        // Stop further attempts in this session to prevent loops/jank.
        _hasMore = false;
        return;
      }
    }
  }
}
