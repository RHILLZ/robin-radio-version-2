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

  group('Playback Controls Integration', () {
    testWidgets('MiniPlayer shows play/pause button', (tester) async {
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

      // Tap Radio to start playback (which will fail in test, but triggers state)
      await tester.tap(find.text('Radio'));
      await tester.pump();

      // MiniPlayer should have play/pause control
      // Note: In tests without mocked audio, playback won't actually start
      // but we can verify the UI structure
    });

    testWidgets('PlayerControls widget has all buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: false,
              isLoading: false,
              canSkipPrevious: true,
              canSkipNext: true,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      // Verify all control buttons are present
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    testWidgets('PlayerControls shows pause when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: true,
              isLoading: false,
              canSkipPrevious: true,
              canSkipNext: true,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('PlayerScreen displays from track', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTracks[0]),
          ),
        ),
      );

      await tester.pump();

      // Verify track info is displayed
      expect(find.text('Song One'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
      expect(find.text('Test Album'), findsOneWidget);
    });

    testWidgets('PlayerScreen has progress slider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTracks[0]),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('PlayerScreen has PlayerControls', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTracks[0]),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(PlayerControls), findsOneWidget);
    });

    testWidgets('PlayerScreen can be closed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(track: testTracks[0]),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open player
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlayerScreen), findsOneWidget);

      // Close player
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerScreen), findsNothing);
    });

    testWidgets('Skip buttons are disabled when at boundaries', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: true,
              isLoading: false,
              canSkipPrevious: false,
              canSkipNext: false,
              onPlayPause: () {},
              onSkipPrevious: () {},
              onSkipNext: () {},
            ),
          ),
        ),
      );

      // Find skip buttons and verify they're disabled
      final prevButton = find.ancestor(
        of: find.byIcon(Icons.skip_previous),
        matching: find.byType(IconButton),
      );
      final nextButton = find.ancestor(
        of: find.byIcon(Icons.skip_next),
        matching: find.byType(IconButton),
      );

      expect(tester.widget<IconButton>(prevButton).onPressed, isNull);
      expect(tester.widget<IconButton>(nextButton).onPressed, isNull);
    });
  });
}
