import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/widgets/album_card.dart';
import 'package:robin_radio/widgets/album_grid.dart';
import 'package:robin_radio/widgets/skeleton_album_card.dart';

void main() {
  // Albums without cover URLs to bypass loading state in tests
  // (CachedNetworkImage never completes loading with fake URLs)
  const testAlbums = <Album>[
    Album(
      id: 'album-1',
      title: 'Abbey Road',
      artistId: 'artist-1',
      artistName: 'The Beatles',
      coverUrl: '', // Empty URL for immediate loaded state in tests
      storagePath: 'Artists/The Beatles/Abbey Road',
      trackCount: 17,
    ),
    Album(
      id: 'album-2',
      title: 'Dark Side of the Moon',
      artistId: 'artist-2',
      artistName: 'Pink Floyd',
      coverUrl: '', // Empty URL for immediate loaded state in tests
      storagePath: 'Artists/Pink Floyd/Dark Side of the Moon',
      trackCount: 10,
    ),
    Album(
      id: 'album-3',
      title: 'Thriller',
      artistId: 'artist-3',
      artistName: 'Michael Jackson',
      coverUrl: '', // Empty URL for immediate loaded state in tests
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
      // Create many albums to test scrolling (empty coverUrl for immediate loaded state)
      final manyAlbums = List.generate(
        20,
        (i) => Album(
          id: 'album-$i',
          title: 'Album $i',
          artistId: 'artist-$i',
          artistName: 'Artist $i',
          coverUrl: '', // Empty URL for immediate loaded state in tests
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

    testWidgets('shows skeleton grid when loading and empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumGrid(
              albums: const [],
              onAlbumTap: (_) {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Should show skeleton grid, not album cards
      expect(find.byType(SkeletonAlbumGrid), findsOneWidget);
      expect(find.byType(AlbumCard), findsNothing);
    });

    testWidgets('shows albums when loading but has data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumGrid(
              albums: testAlbums,
              onAlbumTap: (_) {},
              isLoading: true,
            ),
          ),
        ),
      );

      // Should show actual albums, not skeletons
      expect(find.byType(AlbumCard), findsNWidgets(3));
      expect(find.byType(SkeletonAlbumGrid), findsNothing);
    });

    testWidgets('uses custom skeleton count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumGrid(
              albums: const [],
              onAlbumTap: (_) {},
              isLoading: true,
              skeletonCount: 8,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonAlbumCard), findsNWidgets(8));
    });
  });
}
