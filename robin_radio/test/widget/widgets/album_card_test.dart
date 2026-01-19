import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/widgets/album_card.dart';

void main() {
  const testAlbum = Album(
    id: 'album-1',
    title: 'Abbey Road',
    artistId: 'artist-1',
    artistName: 'The Beatles',
    coverUrl: 'https://example.com/cover.jpg',
    storagePath: 'Artists/The Beatles/Abbey Road',
    trackCount: 17,
  );

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
      await tester.pumpWidget(buildTestableAlbumCard(testAlbum));
      expect(find.text('Abbey Road'), findsOneWidget);
    });

    testWidgets('displays artist name', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbum));
      expect(find.text('The Beatles'), findsOneWidget);
    });

    testWidgets('displays album cover image', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbum));
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('displays placeholder when no cover URL', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbumNoCover));
      expect(find.byIcon(Icons.album), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestableAlbumCard(testAlbum, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(AlbumCard));
      expect(tapped, isTrue);
    });

    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbum));

      final semantics = tester.getSemantics(find.byType(AlbumCard));
      expect(semantics.label, contains('Abbey Road'));
      expect(semantics.label, contains('The Beatles'));
    });

    testWidgets('has square aspect ratio for cover', (tester) async {
      await tester.pumpWidget(buildTestableAlbumCard(testAlbum));
      await tester.pumpAndSettle();

      // Find the AspectRatio widget
      expect(find.byType(AspectRatio), findsOneWidget);
    });
  });
}
