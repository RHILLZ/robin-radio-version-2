import 'album.dart';
import 'artist.dart';
import 'track.dart';

/// Events emitted during progressive catalog loading
sealed class CatalogEvent {}

/// Emitted when a single album is discovered and processed
class AlbumDiscovered extends CatalogEvent {
  final Artist artist;
  final Album album;
  final List<Track> tracks;

  AlbumDiscovered({
    required this.artist,
    required this.album,
    required this.tracks,
  });
}

/// Emitted when catalog loading completes successfully
class CatalogLoadComplete extends CatalogEvent {
  final int totalAlbums;
  final int totalTracks;

  CatalogLoadComplete({
    required this.totalAlbums,
    required this.totalTracks,
  });
}

/// Emitted when an error occurs during catalog loading
class CatalogLoadError extends CatalogEvent {
  final String message;
  final Object? error;

  CatalogLoadError({
    required this.message,
    this.error,
  });
}
