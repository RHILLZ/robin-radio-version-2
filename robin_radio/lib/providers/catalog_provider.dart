import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';

/// State for the catalog
class CatalogState {
  final List<Artist> artists;
  final List<Album> albums;
  final List<Track> tracks;
  final bool isLoading;
  final bool isLoadingComplete;
  final String? error;

  const CatalogState({
    this.artists = const [],
    this.albums = const [],
    this.tracks = const [],
    this.isLoading = false,
    this.isLoadingComplete = false,
    this.error,
  });

  bool get isLoaded => artists.isNotEmpty || albums.isNotEmpty;

  /// Returns true if still loading more albums
  bool get hasMoreToLoad => isLoading && !isLoadingComplete;

  CatalogState copyWith({
    List<Artist>? artists,
    List<Album>? albums,
    List<Track>? tracks,
    bool? isLoading,
    bool? isLoadingComplete,
    String? error,
  }) {
    return CatalogState(
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
      isLoadingComplete: isLoadingComplete ?? this.isLoadingComplete,
      error: error,
    );
  }
}

/// Provider for the CatalogService
final catalogServiceProvider = Provider<CatalogService>((ref) {
  return StorageCatalogService();
});

/// Notifier for catalog state management
class CatalogNotifier extends StateNotifier<CatalogState> {
  final CatalogService _catalogService;
  StreamSubscription<CatalogEvent>? _loadSubscription;

  CatalogNotifier(this._catalogService) : super(const CatalogState());

  /// Loads the catalog from storage using streaming for progressive updates
  Future<void> loadCatalog() async {
    if (state.isLoading) return;

    // Cancel any existing subscription
    await _loadSubscription?.cancel();

    state = state.copyWith(
      isLoading: true,
      isLoadingComplete: false,
      error: null,
    );

    // Working lists for incremental updates
    final artists = <Artist>[...state.artists];
    final albums = <Album>[...state.albums];
    final tracks = <Track>[...state.tracks];
    final artistsById = <String, Artist>{};

    // Initialize artist map from existing state
    for (final artist in artists) {
      artistsById[artist.id] = artist;
    }

    _loadSubscription = _catalogService.loadCatalogStream().listen(
      (event) {
        switch (event) {
          case AlbumDiscovered():
            // Add album and tracks
            albums.add(event.album);
            tracks.addAll(event.tracks);

            // Update artist (may already exist with updated album count)
            artistsById[event.artist.id] = event.artist;

            // Update state - triggers UI rebuild
            state = state.copyWith(
              artists: List.unmodifiable(artistsById.values.toList()),
              albums: List.unmodifiable(albums),
              tracks: List.unmodifiable(tracks),
            );

          case CatalogLoadComplete():
            state = state.copyWith(
              isLoading: false,
              isLoadingComplete: true,
            );

          case CatalogLoadError():
            // Log the actual error for debugging
            print('Catalog load error: ${event.error}');

            // Provide user-friendly error message
            String userMessage = event.message;
            final errorStr = event.error?.toString() ?? '';
            if (errorStr.contains('network') ||
                errorStr.contains('SocketException')) {
              userMessage =
                  'No internet connection. Please check your network.';
            } else if (errorStr.contains('permission') ||
                errorStr.contains('unauthorized') ||
                errorStr.contains('403')) {
              userMessage = 'Permission denied. Check Firebase Storage rules.';
            }
            state = state.copyWith(
              isLoading: false,
              isLoadingComplete: true,
              error: userMessage,
            );
        }
      },
      onError: (e) {
        print('Catalog stream error: $e');
        state = state.copyWith(
          isLoading: false,
          isLoadingComplete: true,
          error: 'Unable to load your music library',
        );
      },
    );
  }

  @override
  void dispose() {
    _loadSubscription?.cancel();
    super.dispose();
  }

  /// Gets albums for a specific artist
  List<Album> getAlbumsForArtist(String artistId) {
    return state.albums.where((album) => album.artistId == artistId).toList();
  }

  /// Gets tracks for a specific album
  List<Track> getTracksForAlbum(String albumId) {
    return state.tracks
        .where((track) => track.albumId == albumId)
        .toList()
      ..sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
  }

  /// Gets all tracks (for Radio mode shuffle)
  List<Track> getAllTracks() {
    return List.unmodifiable(state.tracks);
  }

  /// Refreshes the catalog from storage
  Future<void> refresh() async {
    state = const CatalogState();
    await loadCatalog();
  }
}

/// Main catalog provider
final catalogProvider =
    StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final service = ref.watch(catalogServiceProvider);
  return CatalogNotifier(service);
});

/// Convenience providers for specific data
final artistsProvider = Provider<List<Artist>>((ref) {
  return ref.watch(catalogProvider).artists;
});

final albumsProvider = Provider<List<Album>>((ref) {
  return ref.watch(catalogProvider).albums;
});

final tracksProvider = Provider<List<Track>>((ref) {
  return ref.watch(catalogProvider).tracks;
});

final catalogLoadingProvider = Provider<bool>((ref) {
  return ref.watch(catalogProvider).isLoading;
});

final catalogErrorProvider = Provider<String?>((ref) {
  return ref.watch(catalogProvider).error;
});
