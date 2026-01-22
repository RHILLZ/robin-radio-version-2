import 'package:firebase_storage/firebase_storage.dart';

import '../models/models.dart';
import 'catalog_service.dart';

/// Implementation of CatalogService that scans Firebase Storage
class StorageCatalogService implements CatalogService {
  final FirebaseStorage _storage;

  List<Artist> _artists = [];
  List<Album> _albums = [];
  List<Track> _tracks = [];
  bool _isLoaded = false;

  // Track artists by ID for incremental updates
  final Map<String, Artist> _artistsById = {};

  StorageCatalogService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  bool get isLoaded => _isLoaded;

  @override
  List<Artist> getArtists() => List.unmodifiable(_artists);

  @override
  List<Album> getAlbums() => List.unmodifiable(_albums);

  @override
  List<Track> getTracks() => List.unmodifiable(_tracks);

  @override
  List<Album> getAlbumsForArtist(String artistId) {
    return _albums.where((album) => album.artistId == artistId).toList();
  }

  @override
  List<Track> getTracksForAlbum(String albumId) {
    return _tracks
        .where((track) => track.albumId == albumId)
        .toList()
      ..sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
  }

  @override
  Stream<CatalogEvent> loadCatalogStream() async* {
    // Reset state for fresh load
    _artists = [];
    _albums = [];
    _tracks = [];
    _artistsById.clear();
    _isLoaded = false;

    try {
      // List all artists under "Artist/" prefix
      final artistRef = _storage.ref('Artist/');
      final artistResult = await artistRef.listAll();

      for (final artistPrefix in artistResult.prefixes) {
        final artistName = artistPrefix.name;

        // List all albums for this artist
        final albumResult = await artistPrefix.listAll();

        for (final albumPrefix in albumResult.prefixes) {
          // Process single album
          final albumData = await _processAlbum(albumPrefix, artistName);

          // Get or create artist (incrementing album count)
          final artist =
              _getOrCreateArtist(artistPrefix, artistName);

          // Cache incrementally
          _albums.add(albumData.album);
          _tracks.addAll(albumData.tracks);

          // Emit event for this album
          yield AlbumDiscovered(
            artist: artist,
            album: albumData.album,
            tracks: albumData.tracks,
          );
        }
      }

      // Finalize artist list from map
      _artists = _artistsById.values.toList();
      _isLoaded = true;

      yield CatalogLoadComplete(
        totalAlbums: _albums.length,
        totalTracks: _tracks.length,
      );
    } catch (e) {
      yield CatalogLoadError(
        message: 'Failed to load catalog',
        error: e,
      );
    }
  }

  /// Processes a single album folder and returns album + tracks
  Future<({Album album, List<Track> tracks})> _processAlbum(
    Reference albumPrefix,
    String artistName,
  ) async {
    final albumTitle = albumPrefix.name;

    // List all files in the album folder
    final albumContents = await albumPrefix.listAll();

    // Find cover image and audio tracks
    String? coverUrl;
    final albumTracks = <Track>[];

    for (final item in albumContents.items) {
      final filename = item.name.toLowerCase();

      if (filename.endsWith('.jpg') || filename.endsWith('.png')) {
        // This is the cover image
        coverUrl = await item.getDownloadURL();
      } else if (filename.endsWith('.mp3') ||
          filename.endsWith('.m4a') ||
          filename.endsWith('.aac') ||
          filename.endsWith('.wav') ||
          filename.endsWith('.flac') ||
          filename.endsWith('.ogg')) {
        // This is an audio track
        final audioUrl = await item.getDownloadURL();

        // Try to get duration from custom metadata
        int? duration;
        try {
          final metadata = await item.getMetadata();
          final durationStr = metadata.customMetadata?['duration'];
          if (durationStr != null) {
            duration = int.tryParse(durationStr);
          }
        } catch (_) {
          // Metadata fetch failed, continue without duration
        }

        final track = Track.fromStorageItem(
          item,
          artistName,
          albumTitle,
          audioUrl,
          '', // coverUrl set later
          duration: duration,
        );
        albumTracks.add(track);
      }
    }

    // Use placeholder if no cover found
    coverUrl ??= '';

    // Update tracks with cover URL
    final tracksWithCover = albumTracks
        .map((track) => track.copyWith(coverUrl: coverUrl))
        .toList();

    // Create album
    final album = Album.fromStoragePrefix(
      albumPrefix,
      artistName,
      coverUrl,
      tracksWithCover.length,
    );

    return (album: album, tracks: tracksWithCover);
  }

  /// Gets existing artist or creates new one, tracking album count
  Artist _getOrCreateArtist(
    Reference artistPrefix,
    String artistName,
  ) {
    final artistId = artistPrefix.fullPath;

    if (_artistsById.containsKey(artistId)) {
      // Increment album count for existing artist
      final existing = _artistsById[artistId]!;
      final updated = Artist(
        id: existing.id,
        name: existing.name,
        storagePath: existing.storagePath,
        albumCount: existing.albumCount + 1,
      );
      _artistsById[artistId] = updated;
      return updated;
    } else {
      // Create new artist with album count of 1
      final artist = Artist(
        id: Uri.encodeComponent(artistName),
        name: artistName,
        storagePath: artistPrefix.fullPath,
        albumCount: 1,
      );
      _artistsById[artistId] = artist;
      return artist;
    }
  }

  @override
  Future<({List<Artist> artists, List<Album> albums, List<Track> tracks})>
      loadCatalog() async {
    // Use streaming implementation and wait for completion
    await for (final event in loadCatalogStream()) {
      if (event is CatalogLoadComplete || event is CatalogLoadError) {
        break;
      }
    }
    return (artists: _artists, albums: _albums, tracks: _tracks);
  }
}
