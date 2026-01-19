import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/providers/providers.dart';
import 'package:robin_radio/screens/screens.dart';
import 'package:robin_radio/widgets/widgets.dart';

import 'radio_playback_test.mocks.dart';

void main() {
  late MockCatalogService mockCatalogService;

  const testArtist = Artist(
    id: 'artist-1',
    name: 'Test Artist',
    storagePath: 'Artists/Test Artist',
    albumCount: 2,
  );

  const testAlbum1 = Album(
    id: 'album-1',
    title: 'First Album',
    artistId: 'artist-1',
    artistName: 'Test Artist',
    coverUrl: 'https://example.com/cover1.jpg',
    storagePath: 'Artists/Test Artist/First Album',
    trackCount: 3,
  );

  const testAlbum2 = Album(
    id: 'album-2',
    title: 'Second Album',
    artistId: 'artist-1',
    artistName: 'Test Artist',
    coverUrl: 'https://example.com/cover2.jpg',
    storagePath: 'Artists/Test Artist/Second Album',
    trackCount: 2,
  );

  const testTracks = <Track>[
    Track(
      id: 'track-1',
      title: 'Song One',
      albumId: 'album-1',
      albumTitle: 'First Album',
      artistName: 'Test Artist',
      coverUrl: 'https://example.com/cover1.jpg',
      audioUrl: 'https://example.com/song1.mp3',
      storagePath: 'Artists/Test Artist/First Album/01 Song One.mp3',
      trackNumber: 1,
      duration: 210,
    ),
    Track(
      id: 'track-2',
      title: 'Song Two',
      albumId: 'album-1',
      albumTitle: 'First Album',
      artistName: 'Test Artist',
      coverUrl: 'https://example.com/cover1.jpg',
      audioUrl: 'https://example.com/song2.mp3',
      storagePath: 'Artists/Test Artist/First Album/02 Song Two.mp3',
      trackNumber: 2,
      duration: 255,
    ),
    Track(
      id: 'track-3',
      title: 'Song Three',
      albumId: 'album-1',
      albumTitle: 'First Album',
      artistName: 'Test Artist',
      coverUrl: 'https://example.com/cover1.jpg',
      audioUrl: 'https://example.com/song3.mp3',
      storagePath: 'Artists/Test Artist/First Album/03 Song Three.mp3',
      trackNumber: 3,
      duration: 165,
    ),
    Track(
      id: 'track-4',
      title: 'Other Track One',
      albumId: 'album-2',
      albumTitle: 'Second Album',
      artistName: 'Test Artist',
      coverUrl: 'https://example.com/cover2.jpg',
      audioUrl: 'https://example.com/track4.mp3',
      storagePath: 'Artists/Test Artist/Second Album/01 Other Track One.mp3',
      trackNumber: 1,
      duration: 180,
    ),
    Track(
      id: 'track-5',
      title: 'Other Track Two',
      albumId: 'album-2',
      albumTitle: 'Second Album',
      artistName: 'Test Artist',
      coverUrl: 'https://example.com/cover2.jpg',
      audioUrl: 'https://example.com/track5.mp3',
      storagePath: 'Artists/Test Artist/Second Album/02 Other Track Two.mp3',
      trackNumber: 2,
      duration: 200,
    ),
  ];

  setUp(() {
    mockCatalogService = MockCatalogService();
    when(mockCatalogService.getArtists()).thenReturn([testArtist]);
    when(mockCatalogService.getAlbums()).thenReturn([testAlbum1, testAlbum2]);
    when(mockCatalogService.getTracks()).thenReturn(testTracks);
    when(mockCatalogService.isLoaded).thenReturn(true);
    when(mockCatalogService.loadCatalog()).thenAnswer(
      (_) async => (
        artists: [testArtist],
        albums: [testAlbum1, testAlbum2],
        tracks: testTracks,
      ),
    );
  });

  group('Album Browsing Integration', () {
    testWidgets('HomeScreen displays album grid with albums', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Trigger catalog load
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Verify albums are displayed
      expect(find.text('First Album'), findsOneWidget);
      expect(find.text('Second Album'), findsOneWidget);
      expect(find.byType(AlbumCard), findsNWidgets(2));
    });

    testWidgets('Tapping album navigates to AlbumScreen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Trigger catalog load
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Tap the first album
      await tester.tap(find.text('First Album'));
      // Use pump() with duration instead of pumpAndSettle() to avoid
      // timeout from CachedNetworkImage continuous loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify we navigated to AlbumScreen
      expect(find.byType(AlbumScreen), findsOneWidget);
    });

    testWidgets('AlbumScreen shows album tracks', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Trigger catalog load
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Navigate to album
      await tester.tap(find.text('First Album'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify tracks are shown
      expect(find.text('Song One'), findsOneWidget);
      expect(find.text('Song Two'), findsOneWidget);
      expect(find.text('Song Three'), findsOneWidget);

      // Verify tracks from other album are not shown
      expect(find.text('Other Track One'), findsNothing);
    });

    testWidgets('AlbumScreen shows album info in header', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Trigger catalog load
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Navigate to album
      await tester.tap(find.text('First Album'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify album info in header
      expect(find.text('Test Artist \u2022 3 tracks'), findsOneWidget);
    });

    testWidgets('Back navigation returns to HomeScreen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Trigger catalog load
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Navigate to album
      await tester.tap(find.text('First Album'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify we're on AlbumScreen
      expect(find.byType(AlbumScreen), findsOneWidget);

      // Navigate back using the back button in the AppBar
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify we're back on HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AlbumScreen), findsNothing);
    });

    testWidgets('Tapping track calls playFromAlbum', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Trigger catalog load
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Navigate to album
      await tester.tap(find.text('First Album'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap a track
      await tester.tap(find.text('Song Two'));
      await tester.pump();

      // Verify playback state change is initiated
      // (Full playback testing requires mocking just_audio)
    });

    testWidgets('Empty album shows no tracks message', (tester) async {
      // Create an empty album
      const emptyAlbum = Album(
        id: 'empty-album',
        title: 'Empty Album',
        artistId: 'artist-1',
        artistName: 'Test Artist',
        coverUrl: '',
        storagePath: 'Artists/Test Artist/Empty Album',
        trackCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: AlbumScreen(album: emptyAlbum),
          ),
        ),
      );

      // The catalog is already loaded via mockCatalogService
      // but this album has no tracks
      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.text('No tracks'), findsOneWidget);
    });
  });
}
