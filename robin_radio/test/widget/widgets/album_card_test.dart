import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/widgets/album_card.dart';
import 'package:robin_radio/widgets/robin_radio_logo.dart';

void main() {
  // Album with cover URL - will be in loading state in tests
  // since CachedNetworkImage never completes with fake URLs
  const testAlbumWithCover = Album(
    id: 'album-1',
    title: 'Abbey Road',
    artistId: 'artist-1',
    artistName: 'The Beatles',
    coverUrl: 'https://example.com/cover.jpg',
    storagePath: 'Artists/The Beatles/Abbey Road',
    trackCount: 17,
  );

  // Album without cover URL - immediately in loaded state
  const testAlbumNoCover = Album(
    id: 'album-2',
    title: 'No Cover Album',
    artistId: 'artist-1',
    artistName: 'Test Artist',
    coverUrl: '',
    storagePath: 'Artists/Test Artist/No Cover Album',
    trackCount: 5,
  );

  // Helper to wrap AlbumCard with proper constraints for testing
  Widget buildTestableAlbumCard(Album album, {VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 150,
          height: 200,
          child: AlbumCard(
            album: album,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  group('AlbumCard', () {
    testWidgets('displays album title', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbumWithCover));
      expect(find.text('Abbey Road'), findsOneWidget);
    });

    testWidgets('displays artist name', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbumWithCover));
      expect(find.text('The Beatles'), findsOneWidget);
    });

    testWidgets('displays album cover image', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbumWithCover));
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('displays placeholder when no cover URL', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbumNoCover));
      expect(find.byType(RobinRadioLogo), findsOneWidget);
    });

    testWidgets('shows loading indicator while image loads', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbumWithCover));
      // Use pump() instead of pumpAndSettle() since CircularProgressIndicator
      // animation never stops in test environment
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('blocks taps while loading image', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestableAlbumCard(testAlbumWithCover, onTap: () => tapped = true),
      );
      await tester.pump();

      // Tapping should be blocked while loading
      await tester.tap(find.byType(AlbumCard));
      expect(tapped, isFalse);
    });

    testWidgets('calls onTap when album has no cover (immediately loaded)',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestableAlbumCard(testAlbumNoCover, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(AlbumCard));
      expect(tapped, isTrue);
    });

    testWidgets('has semantic label for accessibility when loading',
        (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbumWithCover));

      final semantics = tester.getSemantics(find.byType(AlbumCard));
      expect(semantics.label, contains('Abbey Road'));
      expect(semantics.label, contains('The Beatles'));
      expect(semantics.label, contains('loading'));
    });

    testWidgets('has semantic label for accessibility when loaded',
        (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbumNoCover));

      final semantics = tester.getSemantics(find.byType(AlbumCard));
      expect(semantics.label, contains('No Cover Album'));
      expect(semantics.label, contains('Test Artist'));
      expect(semantics.label, isNot(contains('loading')));
    });

    testWidgets('has square aspect ratio for cover', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbumNoCover));
      // Use pump() for albums with no cover (immediately loaded)
      await tester.pump();

      // Find the AspectRatio widget
      expect(find.byType(AspectRatio), findsOneWidget);
    });
  });
}
