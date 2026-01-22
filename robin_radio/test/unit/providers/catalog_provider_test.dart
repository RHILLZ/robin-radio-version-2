import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/providers/catalog_provider.dart';
import 'package:robin_radio/services/catalog_service.dart';

import 'catalog_provider_test.mocks.dart';

@GenerateMocks([CatalogService])
void main() {
  late MockCatalogService mockCatalogService;

  /// Helper to create a catalog stream from data
  Stream<CatalogEvent> createCatalogStream({
    List<Artist> artists = const [],
    List<Album> albums = const [],
    List<Track> tracks = const [],
  }) async* {
    // Emit each album as discovered
    for (final album in albums) {
      final albumTracks = tracks.where((t) => t.albumId == album.id).toList();
      final artist = artists.firstWhere(
        (a) => a.id == album.artistId,
        orElse: () => Artist(
          id: album.artistId,
          name: album.artistName,
          storagePath: '',
          albumCount: 1,
        ),
      );
      yield AlbumDiscovered(artist: artist, album: album, tracks: albumTracks);
    }
    yield CatalogLoadComplete(
      totalAlbums: albums.length,
      totalTracks: tracks.length,
    );
  }

  /// Helper to create an error stream
  Stream<CatalogEvent> createErrorStream(String message) async* {
    yield CatalogLoadError(message: message, error: Exception(message));
  }

  setUp(() {
    mockCatalogService = MockCatalogService();
  });

  group('CatalogState', () {
    test('initial state has empty lists', () {
      const state = CatalogState();
      expect(state.artists, isEmpty);
      expect(state.albums, isEmpty);
      expect(state.tracks, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isLoaded, isFalse);
    });

    test('isLoaded returns true when data is present', () {
      const state = CatalogState(
        artists: [
          Artist(
            id: '1',
            name: 'Test',
            storagePath: 'test',
            albumCount: 1,
          ),
        ],
      );
      expect(state.isLoaded, isTrue);
    });

    test('copyWith creates new state with updated values', () {
      const original = CatalogState(isLoading: true);
      final updated = original.copyWith(isLoading: false, error: 'Error');

      expect(original.isLoading, isTrue);
      expect(updated.isLoading, isFalse);
      expect(updated.error, equals('Error'));
    });

    test('hasMoreToLoad returns true when loading but not complete', () {
      const loading = CatalogState(isLoading: true, isLoadingComplete: false);
      const complete = CatalogState(isLoading: false, isLoadingComplete: true);

      expect(loading.hasMoreToLoad, isTrue);
      expect(complete.hasMoreToLoad, isFalse);
    });
  });

  group('CatalogNotifier', () {
    test('loadCatalog updates state with catalog data', () async {
      const testArtist = Artist(
        id: 'artist1',
        name: 'Test Artist',
        storagePath: 'Artist/Test Artist',
        albumCount: 1,
      );

      const testAlbum = Album(
        id: 'album1',
        title: 'Test Album',
        artistId: 'artist1',
        artistName: 'Test Artist',
        coverUrl: 'https://example.com/cover.jpg',
        storagePath: 'Artist/Test Artist/Test Album',
        trackCount: 2,
      );

      const testTrack = Track(
        id: 'track1',
        title: 'Test Track',
        albumId: 'album1',
        albumTitle: 'Test Album',
        artistName: 'Test Artist',
        trackNumber: 1,
        audioUrl: 'https://example.com/track.mp3',
        coverUrl: 'https://example.com/cover.jpg',
        storagePath: 'Artist/Test Artist/Test Album/01 Test Track.mp3',
      );

      when(mockCatalogService.loadCatalogStream()).thenAnswer(
        (_) => createCatalogStream(
          artists: [testArtist],
          albums: [testAlbum],
          tracks: [testTrack],
        ),
      );

      final notifier = CatalogNotifier(mockCatalogService);

      // Initially empty
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.artists, isEmpty);

      // Load catalog
      await notifier.loadCatalog();

      // Give stream time to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify loaded state
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.albums.length, equals(1));
      expect(notifier.state.tracks.length, equals(1));
    });

    test('loadCatalog handles errors gracefully', () async {
      when(mockCatalogService.loadCatalogStream())
          .thenAnswer((_) => createErrorStream('Network error'));

      final notifier = CatalogNotifier(mockCatalogService);
      await notifier.loadCatalog();

      // Give stream time to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.artists, isEmpty);
    });

    test('loadCatalog does not reload while loading', () async {
      when(mockCatalogService.loadCatalogStream()).thenAnswer(
        (_) async* {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          yield CatalogLoadComplete(totalAlbums: 0, totalTracks: 0);
        },
      );

      final notifier = CatalogNotifier(mockCatalogService);

      // Start loading (don't await - want it to run in background)
      unawaited(notifier.loadCatalog());

      // Small delay to ensure isLoading is set before second call
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Try to load again while first is in progress
      unawaited(notifier.loadCatalog());

      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Should only have called loadCatalogStream once
      verify(mockCatalogService.loadCatalogStream()).called(1);
    });

    test('getAlbumsForArtist filters correctly', () async {
      const album1 = Album(
        id: 'album1',
        title: 'Album 1',
        artistId: 'artist1',
        artistName: 'Artist 1',
        coverUrl: '',
        storagePath: '',
        trackCount: 0,
      );

      const album2 = Album(
        id: 'album2',
        title: 'Album 2',
        artistId: 'artist2',
        artistName: 'Artist 2',
        coverUrl: '',
        storagePath: '',
        trackCount: 0,
      );

      when(mockCatalogService.loadCatalogStream()).thenAnswer(
        (_) => createCatalogStream(albums: [album1, album2]),
      );

      final notifier = CatalogNotifier(mockCatalogService);
      await notifier.loadCatalog();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final albums = notifier.getAlbumsForArtist('artist1');
      expect(albums.length, equals(1));
      expect(albums.first.title, equals('Album 1'));
    });

    test('getTracksForAlbum filters and sorts correctly', () async {
      const album = Album(
        id: 'album1',
        title: 'Album',
        artistId: 'artist1',
        artistName: 'Artist',
        coverUrl: '',
        storagePath: '',
        trackCount: 3,
      );

      const track1 = Track(
        id: 'track1',
        title: 'First',
        albumId: 'album1',
        albumTitle: 'Album',
        artistName: 'Artist',
        trackNumber: 1,
        audioUrl: '',
        coverUrl: '',
        storagePath: '',
      );

      const track3 = Track(
        id: 'track3',
        title: 'Third',
        albumId: 'album1',
        albumTitle: 'Album',
        artistName: 'Artist',
        trackNumber: 3,
        audioUrl: '',
        coverUrl: '',
        storagePath: '',
      );

      const track2 = Track(
        id: 'track2',
        title: 'Second',
        albumId: 'album1',
        albumTitle: 'Album',
        artistName: 'Artist',
        trackNumber: 2,
        audioUrl: '',
        coverUrl: '',
        storagePath: '',
      );

      const otherAlbum = Album(
        id: 'album2',
        title: 'Other Album',
        artistId: 'artist1',
        artistName: 'Artist',
        coverUrl: '',
        storagePath: '',
        trackCount: 1,
      );

      const otherTrack = Track(
        id: 'other',
        title: 'Other',
        albumId: 'album2',
        albumTitle: 'Other Album',
        artistName: 'Artist',
        trackNumber: 1,
        audioUrl: '',
        coverUrl: '',
        storagePath: '',
      );

      when(mockCatalogService.loadCatalogStream()).thenAnswer(
        (_) => createCatalogStream(
          albums: [album, otherAlbum],
          tracks: [track3, track1, otherTrack, track2],
        ),
      );

      final notifier = CatalogNotifier(mockCatalogService);
      await notifier.loadCatalog();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final tracks = notifier.getTracksForAlbum('album1');
      expect(tracks.length, equals(3));
      expect(tracks[0].title, equals('First'));
      expect(tracks[1].title, equals('Second'));
      expect(tracks[2].title, equals('Third'));
    });

    test('getAllTracks returns all tracks', () async {
      const album1 = Album(
        id: 'album1',
        title: 'Album',
        artistId: 'artist1',
        artistName: 'Artist',
        coverUrl: '',
        storagePath: '',
        trackCount: 1,
      );

      const album2 = Album(
        id: 'album2',
        title: 'Album 2',
        artistId: 'artist1',
        artistName: 'Artist',
        coverUrl: '',
        storagePath: '',
        trackCount: 1,
      );

      final tracks = [
        const Track(
          id: 'track1',
          title: 'Track 1',
          albumId: 'album1',
          albumTitle: 'Album',
          artistName: 'Artist',
          trackNumber: 1,
          audioUrl: '',
          coverUrl: '',
          storagePath: '',
        ),
        const Track(
          id: 'track2',
          title: 'Track 2',
          albumId: 'album2',
          albumTitle: 'Album 2',
          artistName: 'Artist',
          trackNumber: 1,
          audioUrl: '',
          coverUrl: '',
          storagePath: '',
        ),
      ];

      when(mockCatalogService.loadCatalogStream()).thenAnswer(
        (_) => createCatalogStream(albums: [album1, album2], tracks: tracks),
      );

      final notifier = CatalogNotifier(mockCatalogService);
      await notifier.loadCatalog();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final allTracks = notifier.getAllTracks();
      expect(allTracks.length, equals(2));
    });

    test('refresh clears and reloads catalog', () async {
      when(mockCatalogService.loadCatalogStream()).thenAnswer(
        (_) => createCatalogStream(),
      );

      final notifier = CatalogNotifier(mockCatalogService);
      await notifier.loadCatalog();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await notifier.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(mockCatalogService.loadCatalogStream()).called(2);
    });
  });

  group('Providers', () {
    test('catalogProvider provides CatalogNotifier', () {
      when(mockCatalogService.loadCatalogStream()).thenAnswer(
        (_) => createCatalogStream(),
      );

      final container = ProviderContainer(
        overrides: [
          catalogServiceProvider.overrideWithValue(mockCatalogService),
        ],
      );

      final notifier = container.read(catalogProvider.notifier);
      expect(notifier, isA<CatalogNotifier>());

      container.dispose();
    });

    test('convenience providers return correct data', () async {
      const artist = Artist(
        id: '1',
        name: 'Test',
        storagePath: 'test',
        albumCount: 1,
      );

      const album = Album(
        id: '1',
        title: 'Album',
        artistId: '1',
        artistName: 'Test',
        coverUrl: '',
        storagePath: '',
        trackCount: 1,
      );

      const track = Track(
        id: '1',
        title: 'Track',
        albumId: '1',
        albumTitle: 'Album',
        artistName: 'Test',
        trackNumber: 1,
        audioUrl: '',
        coverUrl: '',
        storagePath: '',
      );

      when(mockCatalogService.loadCatalogStream()).thenAnswer(
        (_) => createCatalogStream(
          artists: [artist],
          albums: [album],
          tracks: [track],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          catalogServiceProvider.overrideWithValue(mockCatalogService),
        ],
      );

      await container.read(catalogProvider.notifier).loadCatalog();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(albumsProvider).length, equals(1));
      expect(container.read(tracksProvider).length, equals(1));
      expect(container.read(catalogLoadingProvider), isFalse);
      expect(container.read(catalogErrorProvider), isNull);

      container.dispose();
    });
  });
}
