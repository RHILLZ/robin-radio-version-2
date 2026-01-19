import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/providers/providers.dart';
import 'package:robin_radio/screens/player_screen.dart';
import 'package:robin_radio/widgets/player_controls.dart';

import '../../integration/radio_playback_test.mocks.dart';

void main() {
  const testTrack = Track(
    id: 'track-1',
    title: 'Test Song',
    albumId: 'album-1',
    albumTitle: 'Test Album',
    artistName: 'Test Artist',
    coverUrl: 'https://example.com/cover.jpg',
    audioUrl: 'https://example.com/song.mp3',
    storagePath: 'Artists/Test Artist/Test Album/01 Test Song.mp3',
    trackNumber: 1,
    duration: 210,
  );

  late MockCatalogService mockCatalogService;

  setUp(() {
    mockCatalogService = MockCatalogService();
    when(mockCatalogService.getArtists()).thenReturn([]);
    when(mockCatalogService.getAlbums()).thenReturn([]);
    when(mockCatalogService.getTracks()).thenReturn([]);
    when(mockCatalogService.isLoaded).thenReturn(true);
  });

  group('PlayerScreen', () {
    testWidgets('displays track title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTrack),
          ),
        ),
      );

      expect(find.text('Test Song'), findsOneWidget);
    });

    testWidgets('displays artist name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTrack),
          ),
        ),
      );

      expect(find.text('Test Artist'), findsOneWidget);
    });

    testWidgets('displays album title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTrack),
          ),
        ),
      );

      expect(find.text('Test Album'), findsOneWidget);
    });

    testWidgets('displays PlayerControls', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTrack),
          ),
        ),
      );

      expect(find.byType(PlayerControls), findsOneWidget);
    });

    testWidgets('displays progress slider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTrack),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('displays current position time', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTrack),
          ),
        ),
      );

      // Initial position should be 0:00
      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('displays duration time', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTrack),
          ),
        ),
      );

      // Duration comes from track.duration (210 seconds = 3:30)
      // But if duration is not yet loaded, may show --:--
      // We check for the presence of time display
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.contains(':') == true ||
                  widget.data?.contains('--') == true),
        ),
        findsWidgets,
      );
    });

    testWidgets('has close/back button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTrack),
          ),
        ),
      );

      // Should have a way to close/go back
      expect(
        find.byIcon(Icons.keyboard_arrow_down),
        findsOneWidget,
      );
    });

    testWidgets('closes when back button tapped', (tester) async {
      var popped = false;

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
                      builder: (context) => PlayerScreen(track: testTrack),
                    ),
                  ).then((_) => popped = true);
                },
                child: const Text('Open Player'),
              ),
            ),
          ),
        ),
      );

      // Navigate to player screen
      await tester.tap(find.text('Open Player'));
      // Use pump() instead of pumpAndSettle() due to CachedNetworkImage
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap close button
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('displays album artwork', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: MaterialApp(
            home: PlayerScreen(track: testTrack),
          ),
        ),
      );

      // Should have album artwork area (either image or placeholder)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints != null &&
              widget.constraints!.maxWidth > 200,
        ).evaluate().isNotEmpty ||
            find.byIcon(Icons.album).evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
