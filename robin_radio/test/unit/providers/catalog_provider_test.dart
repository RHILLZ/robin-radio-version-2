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

      when(mockCatalogService.loadCatalog()).thenAnswer(
        (_) async => (
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

      // Verify loaded state
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.artists.length, equals(1));
      expect(notifier.state.albums.length, equals(1));
      expect(notifier.state.tracks.length, equals(1));
      expect(notifier.state.artists.first.name, equals('Test Artist'));
    });

    test('loadCatalog handles errors gracefully', () async {
      when(mockCatalogService.loadCatalog())
          .thenThrow(Exception('Network error'));

      final notifier = CatalogNotifier(mockCatalogService);
      await notifier.loadCatalog();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, contains('Failed to load catalog'));
      expect(notifier.state.artists, isEmpty);
    });

    test('loadCatalog does not reload while loading', () async {
      when(mockCatalogService.loadCatalog()).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return (artists: <Artist>[], albums: <Album>[], tracks: <Track>[]);
        },
      );

      final notifier = CatalogNotifier(mockCatalogService);

      // Start loading
      final future1 = notifier.loadCatalog();

      // Try to load again while first is in progress
      final future2 = notifier.loadCatalog();

      await Future.wait([future1, future2]);

      // Should only have called loadCatalog once
      verify(mockCatalogService.loadCatalog()).called(1);
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

      when(mockCatalogService.loadCatalog()).thenAnswer(
        (_) async => (
          artists: <Artist>[],
          albums: [album1, album2],
          tracks: <Track>[],
        ),
      );

      final notifier = CatalogNotifier(mockCatalogService);
      await notifier.loadCatalog();

      final albums = notifier.getAlbumsForArtist('artist1');
      expect(albums.length, equals(1));
      expect(albums.first.title, equals('Album 1'));
    });

    test('getTracksForAlbum filters and sorts correctly', () async {
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

      when(mockCatalogService.loadCatalog()).thenAnswer(
        (_) async => (
          artists: <Artist>[],
          albums: <Album>[],
          tracks: [track3, track1, otherTrack, track2],
        ),
      );

      final notifier = CatalogNotifier(mockCatalogService);
      await notifier.loadCatalog();

      final tracks = notifier.getTracksForAlbum('album1');
      expect(tracks.length, equals(3));
      expect(tracks[0].title, equals('First'));
      expect(tracks[1].title, equals('Second'));
      expect(tracks[2].title, equals('Third'));
    });

    test('getAllTracks returns all tracks', () async {
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

      when(mockCatalogService.loadCatalog()).thenAnswer(
        (_) async => (artists: <Artist>[], albums: <Album>[], tracks: tracks),
      );

      final notifier = CatalogNotifier(mockCatalogService);
      await notifier.loadCatalog();

      final allTracks = notifier.getAllTracks();
      expect(allTracks.length, equals(2));
    });

    test('refresh clears and reloads catalog', () async {
      when(mockCatalogService.loadCatalog()).thenAnswer(
        (_) async => (artists: <Artist>[], albums: <Album>[], tracks: <Track>[]),
      );

      final notifier = CatalogNotifier(mockCatalogService);
      await notifier.loadCatalog();
      await notifier.refresh();

      verify(mockCatalogService.loadCatalog()).called(2);
    });
  });

  group('Providers', () {
    test('catalogProvider provides CatalogNotifier', () {
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
      when(mockCatalogService.loadCatalog()).thenAnswer(
        (_) async => (
          artists: [
            const Artist(
              id: '1',
              name: 'Test',
              storagePath: 'test',
              albumCount: 1,
            ),
          ],
          albums: [
            const Album(
              id: '1',
              title: 'Album',
              artistId: '1',
              artistName: 'Test',
              coverUrl: '',
              storagePath: '',
              trackCount: 1,
            ),
          ],
          tracks: [
            const Track(
              id: '1',
              title: 'Track',
              albumId: '1',
              albumTitle: 'Album',
              artistName: 'Test',
              trackNumber: 1,
              audioUrl: '',
              coverUrl: '',
              storagePath: '',
            ),
          ],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          catalogServiceProvider.overrideWithValue(mockCatalogService),
        ],
      );

      await container.read(catalogProvider.notifier).loadCatalog();

      expect(container.read(artistsProvider).length, equals(1));
      expect(container.read(albumsProvider).length, equals(1));
      expect(container.read(tracksProvider).length, equals(1));
      expect(container.read(catalogLoadingProvider), isFalse);
      expect(container.read(catalogErrorProvider), isNull);

      container.dispose();
    });
  });
}
