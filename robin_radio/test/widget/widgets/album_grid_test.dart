import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/widgets/album_card.dart';
import 'package:robin_radio/widgets/album_grid.dart';

void main() {
  const testAlbums = <Album>[
    Album(
      id: 'album-1',
      title: 'Abbey Road',
      artistId: 'artist-1',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/cover1.jpg',
      storagePath: 'Artists/The Beatles/Abbey Road',
      trackCount: 17,
    ),
    Album(
      id: 'album-2',
      title: 'Dark Side of the Moon',
      artistId: 'artist-2',
      artistName: 'Pink Floyd',
      coverUrl: 'https://example.com/cover2.jpg',
      storagePath: 'Artists/Pink Floyd/Dark Side of the Moon',
      trackCount: 10,
    ),
    Album(
      id: 'album-3',
      title: 'Thriller',
      artistId: 'artist-3',
      artistName: 'Michael Jackson',
      coverUrl: 'https://example.com/cover3.jpg',
      storagePath: 'Artists/Michael Jackson/Thriller',
      trackCount: 9,
    ),
  ];

  group('AlbumGrid', () {
    testWidgets('displays all albums', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumGrid(
              albums: testAlbums,
              onAlbumTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Abbey Road'), findsOneWidget);
      expect(find.text('Dark Side of the Moon'), findsOneWidget);
      expect(find.text('Thriller'), findsOneWidget);
    });

    testWidgets('displays AlbumCard for each album', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumGrid(
              albums: testAlbums,
              onAlbumTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AlbumCard), findsNWidgets(3));
    });

    testWidgets('calls onAlbumTap with correct album when tapped',
        (tester) async {
      Album? tappedAlbum;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumGrid(
              albums: testAlbums,
              onAlbumTap: (album) => tappedAlbum = album,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Thriller'));
      expect(tappedAlbum?.title, equals('Thriller'));
    });

    testWidgets('shows empty state when no albums', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumGrid(
              albums: const [],
              onAlbumTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AlbumCard), findsNothing);
    });

    testWidgets('uses GridView for layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumGrid(
              albums: testAlbums,
              onAlbumTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('is scrollable when many albums', (tester) async {
      // Create many albums to test scrolling
      final manyAlbums = List.generate(
        20,
        (i) => Album(
          id: 'album-$i',
          title: 'Album $i',
          artistId: 'artist-$i',
          artistName: 'Artist $i',
          coverUrl: 'https://example.com/cover$i.jpg',
          storagePath: 'Artists/Artist $i/Album $i',
          trackCount: 10,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumGrid(
              albums: manyAlbums,
              onAlbumTap: (_) {},
            ),
          ),
        ),
      );

      // GridView should be scrollable
      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView.physics, isNot(const NeverScrollableScrollPhysics()));
    });
  });
}
