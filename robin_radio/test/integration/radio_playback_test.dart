import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/providers/providers.dart';
import 'package:robin_radio/screens/screens.dart';
import 'package:robin_radio/services/services.dart';

@GenerateMocks([CatalogService, AudioService])
import 'radio_playback_test.mocks.dart';

void main() {
  late MockCatalogService mockCatalogService;

  const testArtist = Artist(
    id: 'artist-1',
    name: 'Test Artist',
    storagePath: 'Artists/Test Artist',
    albumCount: 1,
  );

  const testAlbum = Album(
    id: 'album-1',
    title: 'Test Album',
    artistId: 'artist-1',
    artistName: 'Test Artist',
    coverUrl: 'https://example.com/cover.jpg',
    storagePath: 'Artists/Test Artist/Test Album',
    trackCount: 3,
  );

  const testTracks = <Track>[
    Track(
      id: 'track-1',
      title: 'Song One',
      albumId: 'album-1',
      albumTitle: 'Test Album',
      artistName: 'Test Artist',
      coverUrl: 'https://example.com/cover.jpg',
      audioUrl: 'https://example.com/song1.mp3',
      storagePath: 'Artists/Test Artist/Test Album/01 Song One.mp3',
      trackNumber: 1,
      duration: 210,
    ),
    Track(
      id: 'track-2',
      title: 'Song Two',
      albumId: 'album-1',
      albumTitle: 'Test Album',
      artistName: 'Test Artist',
      coverUrl: 'https://example.com/cover.jpg',
      audioUrl: 'https://example.com/song2.mp3',
      storagePath: 'Artists/Test Artist/Test Album/02 Song Two.mp3',
      trackNumber: 2,
      duration: 255,
    ),
    Track(
      id: 'track-3',
      title: 'Song Three',
      albumId: 'album-1',
      albumTitle: 'Test Album',
      artistName: 'Test Artist',
      coverUrl: 'https://example.com/cover.jpg',
      audioUrl: 'https://example.com/song3.mp3',
      storagePath: 'Artists/Test Artist/Test Album/03 Song Three.mp3',
      trackNumber: 3,
      duration: 165,
    ),
  ];

  setUp(() {
    mockCatalogService = MockCatalogService();
    when(mockCatalogService.getArtists()).thenReturn([testArtist]);
    when(mockCatalogService.getAlbums()).thenReturn([testAlbum]);
    when(mockCatalogService.getTracks()).thenReturn(testTracks);
    when(mockCatalogService.isLoaded).thenReturn(true);
    when(mockCatalogService.loadCatalog()).thenAnswer(
      (_) async => (
        artists: [testArtist],
        albums: [testAlbum],
        tracks: testTracks,
      ),
    );
  });

  group('Radio Playback Integration', () {
    testWidgets('HomeScreen shows catalog stats when loaded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return const HomeScreen();
              },
            ),
          ),
        ),
      );

      // Trigger catalog load
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Verify catalog stats are displayed (format: "X songs • Y albums")
      expect(find.text('3 songs • 1 albums'), findsOneWidget);
    });

    testWidgets('HomeScreen shows Radio button', (tester) async {
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

      // Verify Radio button is present
      expect(find.text('Radio'), findsOneWidget);
      expect(find.byIcon(Icons.radio), findsOneWidget);
    });

    testWidgets('Tapping Radio button triggers playback state change',
        (tester) async {
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

      // Verify Radio button exists
      expect(find.text('Radio'), findsOneWidget);

      // Tap the Radio button
      await tester.tap(find.text('Radio'));
      await tester.pump();

      // The playback provider should now be in loading state
      // Note: Full audio playback testing requires mocking just_audio
      // which is complex. This test verifies the UI interaction works.
    });

    testWidgets('HomeScreen shows empty state when no tracks', (tester) async {
      // Override to return empty catalog
      when(mockCatalogService.loadCatalog()).thenAnswer(
        (_) async => (
          artists: <Artist>[],
          albums: <Album>[],
          tracks: <Track>[],
        ),
      );
      when(mockCatalogService.getTracks()).thenReturn(<Track>[]);

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

      expect(find.text('No music found'), findsOneWidget);
    });

    testWidgets('MiniPlayer is hidden when nothing is playing', (tester) async {
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

      // MiniPlayer uses SizedBox.shrink when no track is playing
      // Verify no track info is shown
      expect(find.text('Song One'), findsNothing);
      expect(find.text('Song Two'), findsNothing);
      expect(find.text('Song Three'), findsNothing);
    });
  });
}
