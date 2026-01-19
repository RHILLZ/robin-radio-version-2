import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/widgets/search_results.dart';

void main() {
  const testArtist = Artist(
    id: 'artist-1',
    name: 'The Beatles',
    storagePath: 'Artists/The Beatles',
    albumCount: 2,
  );

  const testAlbum = Album(
    id: 'album-1',
    title: 'Abbey Road',
    artistId: 'artist-1',
    artistName: 'The Beatles',
    coverUrl: 'https://example.com/abbey.jpg',
    storagePath: 'Artists/The Beatles/Abbey Road',
    trackCount: 3,
  );

  const testTrack = Track(
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
  );

  group('SearchResults', () {
    testWidgets('displays empty state when no results', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: const [],
              query: 'xyz123',
              onResultTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('displays results list', (tester) async {
      final results = [
        SearchResult.fromArtist(testArtist, 100),
        SearchResult.fromAlbum(testAlbum, 95),
        SearchResult.fromTrack(testTrack, 90),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: results,
              query: 'Beatles',
              onResultTap: (_) {},
            ),
          ),
        ),
      );

      // Artist title
      expect(find.text('The Beatles'), findsAtLeast(1));
      // Album title
      expect(find.text('Abbey Road'), findsOneWidget);
      // Track title
      expect(find.text('Come Together'), findsOneWidget);
    });

    testWidgets('shows artist icon for artist results', (tester) async {
      final results = [SearchResult.fromArtist(testArtist, 100)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: results,
              query: 'Beatles',
              onResultTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows album icon for album results without cover', (tester) async {
      const albumNoCover = Album(
        id: 'album-2',
        title: 'Test Album',
        artistId: 'artist-1',
        artistName: 'Test Artist',
        coverUrl: '',
        storagePath: 'path',
        trackCount: 1,
      );
      final results = [SearchResult.fromAlbum(albumNoCover, 100)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: results,
              query: 'Test',
              onResultTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.album), findsOneWidget);
    });

    testWidgets('shows music note icon for track results without cover', (tester) async {
      const trackNoCover = Track(
        id: 'track-2',
        title: 'Test Song',
        albumId: 'album-1',
        albumTitle: 'Test Album',
        artistName: 'Test Artist',
        coverUrl: '',
        audioUrl: 'https://example.com/test.mp3',
        storagePath: 'path',
        trackNumber: 1,
        duration: 180,
      );
      final results = [SearchResult.fromTrack(trackNoCover, 100)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: results,
              query: 'Test',
              onResultTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('calls onResultTap when result is tapped', (tester) async {
      SearchResult? tappedResult;
      final results = [SearchResult.fromArtist(testArtist, 100)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: results,
              query: 'Beatles',
              onResultTap: (result) => tappedResult = result,
            ),
          ),
        ),
      );

      await tester.tap(find.text('The Beatles'));
      expect(tappedResult, equals(results.first));
    });

    testWidgets('displays subtitle for each result type', (tester) async {
      final results = [
        SearchResult.fromArtist(testArtist, 100),
        SearchResult.fromAlbum(testAlbum, 95),
        SearchResult.fromTrack(testTrack, 90),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: results,
              query: 'Beatles',
              onResultTap: (_) {},
            ),
          ),
        ),
      );

      // Artist subtitle shows album count
      expect(find.text('2 albums'), findsOneWidget);

      // Track subtitle shows artist and album
      expect(find.textContaining('The Beatles'), findsWidgets);
    });

    testWidgets('scrolls when many results', (tester) async {
      // Create many results
      final results = List.generate(
        20,
        (i) => SearchResult.fromTrack(
          Track(
            id: 'track-$i',
            title: 'Song $i',
            albumId: 'album-1',
            albumTitle: 'Test Album',
            artistName: 'Test Artist',
            coverUrl: '',
            audioUrl: 'https://example.com/$i.mp3',
            storagePath: 'path',
            trackNumber: i,
            duration: 180,
          ),
          100 - i,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: results,
              query: 'Song',
              onResultTap: (_) {},
            ),
          ),
        ),
      );

      // Should be scrollable
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows result count', (tester) async {
      final results = [
        SearchResult.fromArtist(testArtist, 100),
        SearchResult.fromAlbum(testAlbum, 95),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResults(
              results: results,
              query: 'Beatles',
              onResultTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('2'), findsWidgets);
    });
  });

  group('SearchResultItem', () {
    testWidgets('displays title and subtitle', (tester) async {
      final result = SearchResult.fromAlbum(testAlbum, 95);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              result: result,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Abbey Road'), findsOneWidget);
      expect(find.text('The Beatles'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      final result = SearchResult.fromAlbum(testAlbum, 95);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultItem(
              result: result,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SearchResultItem));
      expect(tapped, isTrue);
    });
  });
}
