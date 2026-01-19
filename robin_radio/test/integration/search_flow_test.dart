import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/providers/providers.dart';
import 'package:robin_radio/screens/screens.dart';

import 'radio_playback_test.mocks.dart';

void main() {
  late MockCatalogService mockCatalogService;

  const testArtist = Artist(
    id: 'artist-1',
    name: 'The Beatles',
    storagePath: 'Artists/The Beatles',
    albumCount: 2,
  );

  const testAlbums = [
    Album(
      id: 'album-1',
      title: 'Abbey Road',
      artistId: 'artist-1',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/abbey.jpg',
      storagePath: 'Artists/The Beatles/Abbey Road',
      trackCount: 2,
    ),
    Album(
      id: 'album-2',
      title: 'Let It Be',
      artistId: 'artist-1',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/letitbe.jpg',
      storagePath: 'Artists/The Beatles/Let It Be',
      trackCount: 1,
    ),
  ];

  const testTracks = [
    Track(
      id: 'track-1',
      title: 'Come Together',
      albumId: 'album-1',
      albumTitle: 'Abbey Road',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/abbey.jpg',
      audioUrl: 'https://example.com/come.mp3',
      storagePath: 'Artists/The Beatles/Abbey Road/01 Come Together.mp3',
      trackNumber: 1,
      duration: 259,
    ),
    Track(
      id: 'track-2',
      title: 'Something',
      albumId: 'album-1',
      albumTitle: 'Abbey Road',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/abbey.jpg',
      audioUrl: 'https://example.com/something.mp3',
      storagePath: 'Artists/The Beatles/Abbey Road/02 Something.mp3',
      trackNumber: 2,
      duration: 183,
    ),
    Track(
      id: 'track-3',
      title: 'Let It Be',
      albumId: 'album-2',
      albumTitle: 'Let It Be',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/letitbe.jpg',
      audioUrl: 'https://example.com/letitbe.mp3',
      storagePath: 'Artists/The Beatles/Let It Be/01 Let It Be.mp3',
      trackNumber: 1,
      duration: 243,
    ),
  ];

  setUp(() {
    mockCatalogService = MockCatalogService();
    when(mockCatalogService.getArtists()).thenReturn([testArtist]);
    when(mockCatalogService.getAlbums()).thenReturn(testAlbums);
    when(mockCatalogService.getTracks()).thenReturn(testTracks);
    when(mockCatalogService.isLoaded).thenReturn(true);
    when(mockCatalogService.loadCatalog()).thenAnswer(
      (_) async => (
        artists: [testArtist],
        albums: testAlbums,
        tracks: testTracks,
      ),
    );
  });

  group('Search Flow Integration', () {
    testWidgets('search icon opens search screen from home', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Load catalog
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Find and tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // SearchScreen should be visible
      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('typing in search bar shows results', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );

      // Load catalog
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Type in search bar
      await tester.enterText(find.byType(TextField), 'Beatles');
      await tester.pump();

      // Results should appear
      expect(find.text('The Beatles'), findsAtLeast(1));
    });

    testWidgets('fuzzy search finds results with typos', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );

      // Load catalog
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Type with typo
      await tester.enterText(find.byType(TextField), 'Betles');
      await tester.pump();

      // Should still find Beatles
      expect(find.text('The Beatles'), findsAtLeast(1));
    });

    testWidgets('tapping album result navigates to album screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );

      // Load catalog
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Search for album
      await tester.enterText(find.byType(TextField), 'Abbey Road');
      await tester.pump();

      // Tap album result (use ListTile to be more specific)
      final listTileFinder = find.ancestor(
        of: find.text('Abbey Road'),
        matching: find.byType(ListTile),
      );
      await tester.tap(listTileFinder.first);
      // Use pump() instead of pumpAndSettle() due to CachedNetworkImage
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should navigate to AlbumScreen
      expect(find.byType(AlbumScreen), findsOneWidget);
    });

    testWidgets('clear button clears search and results', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );

      // Load catalog
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Type in search bar
      await tester.enterText(find.byType(TextField), 'Beatles');
      await tester.pump();

      // Results should appear
      expect(find.text('The Beatles'), findsAtLeast(1));

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Results should be gone (empty state or instructions shown)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('back button returns to previous screen', (tester) async {
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
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: const Text('Open Search'),
              ),
            ),
          ),
        ),
      );

      // Load catalog
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Navigate to search
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsNothing);
    });

    testWidgets('search shows no results message for unmatched query', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogServiceProvider.overrideWithValue(mockCatalogService),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );

      // Load catalog
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)),
      );
      await container.read(catalogProvider.notifier).loadCatalog();
      await tester.pumpAndSettle();

      // Search for something not in catalog
      await tester.enterText(find.byType(TextField), 'xyz123notfound');
      await tester.pump();

      // Should show no results message
      expect(find.text('No results found'), findsOneWidget);
    });
  });
}
