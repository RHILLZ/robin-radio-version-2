import '../models/models.dart';

/// Interface for loading the music catalog from storage
abstract class CatalogService {
  /// Loads the complete catalog from storage
  /// Returns a record containing all artists, albums, and tracks
  Future<({List<Artist> artists, List<Album> albums, List<Track> tracks})>
      loadCatalog();

  /// Streams catalog events as albums are discovered
  /// Emits [AlbumDiscovered] for each album, then [CatalogLoadComplete] or [CatalogLoadError]
  Stream<CatalogEvent> loadCatalogStream();

  /// Returns all artists in the catalog
  List<Artist> getArtists();

  /// Returns all albums in the catalog
  List<Album> getAlbums();

  /// Returns all tracks in the catalog
  List<Track> getTracks();

  /// Returns albums for a specific artist
  List<Album> getAlbumsForArtist(String artistId);

  /// Returns tracks for a specific album
  List<Track> getTracksForAlbum(String albumId);

  /// Indicates if the catalog has been loaded
  bool get isLoaded;
}
