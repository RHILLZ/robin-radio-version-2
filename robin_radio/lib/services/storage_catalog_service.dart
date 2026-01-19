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
  Future<({List<Artist> artists, List<Album> albums, List<Track> tracks})>
      loadCatalog() async {
    final artists = <Artist>[];
    final albums = <Album>[];
    final tracks = <Track>[];

    // List all artists under "Artist/" prefix
    final artistRef = _storage.ref('Artist/');
    final artistResult = await artistRef.listAll();

    for (final artistPrefix in artistResult.prefixes) {
      final artistName = artistPrefix.name;

      // List all albums for this artist
      final albumResult = await artistPrefix.listAll();
      final artistAlbums = <Album>[];

      for (final albumPrefix in albumResult.prefixes) {
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
              filename.endsWith('.aac')) {
            // This is an audio track
            final audioUrl = await item.getDownloadURL();
            final track = Track.fromStorageItem(
              item,
              artistName,
              albumTitle,
              audioUrl,
              '', // coverUrl set later
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

        artistAlbums.add(album);
        albums.add(album);
        tracks.addAll(tracksWithCover);
      }

      // Create artist with album count
      final artist = Artist.fromStoragePrefix(artistPrefix, artistAlbums.length);
      artists.add(artist);
    }

    // Cache results
    _artists = artists;
    _albums = albums;
    _tracks = tracks;
    _isLoaded = true;

    return (artists: artists, albums: albums, tracks: tracks);
  }
}
