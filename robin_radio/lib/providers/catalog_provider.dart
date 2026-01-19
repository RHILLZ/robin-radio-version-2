import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';

/// State for the catalog
class CatalogState {
  final List<Artist> artists;
  final List<Album> albums;
  final List<Track> tracks;
  final bool isLoading;
  final String? error;

  const CatalogState({
    this.artists = const [],
    this.albums = const [],
    this.tracks = const [],
    this.isLoading = false,
    this.error,
  });

  bool get isLoaded => artists.isNotEmpty || albums.isNotEmpty;

  CatalogState copyWith({
    List<Artist>? artists,
    List<Album>? albums,
    List<Track>? tracks,
    bool? isLoading,
    String? error,
  }) {
    return CatalogState(
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
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

  CatalogNotifier(this._catalogService) : super(const CatalogState());

  /// Loads the catalog from storage
  Future<void> loadCatalog() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _catalogService.loadCatalog();
      state = CatalogState(
        artists: result.artists,
        albums: result.albums,
        tracks: result.tracks,
        isLoading: false,
      );
    } catch (e) {
      // Provide user-friendly error message without exposing internal details
      String userMessage = 'Unable to load your music library';
      if (e.toString().contains('network') ||
          e.toString().contains('SocketException')) {
        userMessage = 'No internet connection. Please check your network.';
      }
      state = state.copyWith(
        isLoading: false,
        error: userMessage,
      );
    }
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
