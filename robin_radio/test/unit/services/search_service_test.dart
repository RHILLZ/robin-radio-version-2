import 'package:flutter_test/flutter_test.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/services/search_service.dart';

void main() {
  late SearchService searchService;

  const testArtists = [
    Artist(
      id: 'artist-1',
      name: 'The Beatles',
      storagePath: 'Artists/The Beatles',
      albumCount: 2,
    ),
    Artist(
      id: 'artist-2',
      name: 'Led Zeppelin',
      storagePath: 'Artists/Led Zeppelin',
      albumCount: 1,
    ),
    Artist(
      id: 'artist-3',
      name: 'Pink Floyd',
      storagePath: 'Artists/Pink Floyd',
      albumCount: 1,
    ),
  ];

  const testAlbums = [
    Album(
      id: 'album-1',
      title: 'Abbey Road',
      artistId: 'artist-1',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/abbey.jpg',
      storagePath: 'Artists/The Beatles/Abbey Road',
      trackCount: 3,
    ),
    Album(
      id: 'album-2',
      title: 'Let It Be',
      artistId: 'artist-1',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/letitbe.jpg',
      storagePath: 'Artists/The Beatles/Let It Be',
      trackCount: 2,
    ),
    Album(
      id: 'album-3',
      title: 'Led Zeppelin IV',
      artistId: 'artist-2',
      artistName: 'Led Zeppelin',
      coverUrl: 'https://example.com/lz4.jpg',
      storagePath: 'Artists/Led Zeppelin/Led Zeppelin IV',
      trackCount: 2,
    ),
    Album(
      id: 'album-4',
      title: 'The Dark Side of the Moon',
      artistId: 'artist-3',
      artistName: 'Pink Floyd',
      coverUrl: 'https://example.com/dsotm.jpg',
      storagePath: 'Artists/Pink Floyd/The Dark Side of the Moon',
      trackCount: 2,
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
      title: 'Here Comes The Sun',
      albumId: 'album-1',
      albumTitle: 'Abbey Road',
      artistName: 'The Beatles',
      coverUrl: 'https://example.com/abbey.jpg',
      audioUrl: 'https://example.com/sun.mp3',
      storagePath: 'Artists/The Beatles/Abbey Road/03 Here Comes The Sun.mp3',
      trackNumber: 3,
      duration: 185,
    ),
    Track(
      id: 'track-4',
      title: 'Stairway to Heaven',
      albumId: 'album-3',
      albumTitle: 'Led Zeppelin IV',
      artistName: 'Led Zeppelin',
      coverUrl: 'https://example.com/lz4.jpg',
      audioUrl: 'https://example.com/stairway.mp3',
      storagePath: 'Artists/Led Zeppelin/Led Zeppelin IV/01 Stairway to Heaven.mp3',
      trackNumber: 1,
      duration: 482,
    ),
    Track(
      id: 'track-5',
      title: 'Money',
      albumId: 'album-4',
      albumTitle: 'The Dark Side of the Moon',
      artistName: 'Pink Floyd',
      coverUrl: 'https://example.com/dsotm.jpg',
      audioUrl: 'https://example.com/money.mp3',
      storagePath: 'Artists/Pink Floyd/The Dark Side of the Moon/01 Money.mp3',
      trackNumber: 1,
      duration: 382,
    ),
  ];

  setUp(() {
    searchService = SearchService();
  });

  group('SearchService', () {
    group('search', () {
      test('returns empty results for empty query', () {
        final results = searchService.search(
          query: '',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        expect(results, isEmpty);
      });

      test('returns empty results for whitespace-only query', () {
        final results = searchService.search(
          query: '   ',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        expect(results, isEmpty);
      });

      test('finds exact artist match', () {
        final results = searchService.search(
          query: 'Beatles',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        expect(results.any((r) => r.type == SearchResultType.artist), isTrue);
        final artistResult = results.firstWhere(
          (r) => r.type == SearchResultType.artist,
        );
        expect(artistResult.title, equals('The Beatles'));
      });

      test('finds exact album match', () {
        final results = searchService.search(
          query: 'Abbey Road',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        expect(results.any((r) => r.type == SearchResultType.album), isTrue);
        final albumResult = results.firstWhere(
          (r) => r.type == SearchResultType.album,
        );
        expect(albumResult.title, equals('Abbey Road'));
      });

      test('finds exact track match', () {
        final results = searchService.search(
          query: 'Come Together',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        expect(results.any((r) => r.type == SearchResultType.track), isTrue);
        final trackResult = results.firstWhere(
          (r) => r.type == SearchResultType.track,
        );
        expect(trackResult.title, equals('Come Together'));
      });

      test('search is case-insensitive', () {
        final results = searchService.search(
          query: 'beatles',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        expect(results.any((r) => r.title == 'The Beatles'), isTrue);
      });

      test('finds partial matches', () {
        final results = searchService.search(
          query: 'Zep',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        expect(
          results.any((r) => r.title.contains('Zeppelin')),
          isTrue,
        );
      });
    });

    group('fuzzy matching', () {
      test('finds match with typo - Betles matches Beatles', () {
        final results = searchService.search(
          query: 'Betles',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        expect(
          results.any((r) => r.title == 'The Beatles'),
          isTrue,
          reason: 'Should find Beatles even with typo "Betles"',
        );
      });

      test('finds match with typo - Abby Road matches Abbey Road', () {
        final results = searchService.search(
          query: 'Abby Road',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        expect(
          results.any((r) => r.title == 'Abbey Road'),
          isTrue,
          reason: 'Should find Abbey Road even with typo "Abby"',
        );
      });

      test('finds match with typo - Stairway Heven matches Stairway to Heaven',
          () {
        final results = searchService.search(
          query: 'Stairway Heven',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        expect(
          results.any((r) => r.title == 'Stairway to Heaven'),
          isTrue,
          reason: 'Should find "Stairway to Heaven" with typo',
        );
      });

      test('ranks exact matches higher than fuzzy matches', () {
        final results = searchService.search(
          query: 'Led Zeppelin',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        // Should find both artist "Led Zeppelin" and album "Led Zeppelin IV"
        expect(results.length, greaterThan(1));

        // Artist exact match should rank higher than partial album match
        final artistIndex = results.indexWhere(
          (r) => r.type == SearchResultType.artist && r.title == 'Led Zeppelin',
        );
        final albumIndex = results.indexWhere(
          (r) =>
              r.type == SearchResultType.album &&
              r.title == 'Led Zeppelin IV',
        );

        expect(
          artistIndex,
          lessThan(albumIndex),
          reason: 'Exact artist match should rank higher than partial album',
        );
      });
    });

    group('result properties', () {
      test('artist result has correct properties', () {
        final results = searchService.search(
          query: 'Pink Floyd',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        final artistResult = results.firstWhere(
          (r) => r.type == SearchResultType.artist,
        );

        expect(artistResult.title, equals('Pink Floyd'));
        expect(artistResult.subtitle, contains('album'));
        expect(artistResult.artist, isNotNull);
        expect(artistResult.album, isNull);
        expect(artistResult.track, isNull);
      });

      test('album result has correct properties', () {
        final results = searchService.search(
          query: 'Dark Side',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        final albumResult = results.firstWhere(
          (r) => r.type == SearchResultType.album,
        );

        expect(albumResult.title, equals('The Dark Side of the Moon'));
        expect(albumResult.subtitle, equals('Pink Floyd'));
        expect(albumResult.coverUrl, isNotEmpty);
        expect(albumResult.album, isNotNull);
        expect(albumResult.artist, isNull);
        expect(albumResult.track, isNull);
      });

      test('track result has correct properties', () {
        final results = searchService.search(
          query: 'Money',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        final trackResult = results.firstWhere(
          (r) => r.type == SearchResultType.track,
        );

        expect(trackResult.title, equals('Money'));
        expect(trackResult.subtitle, contains('Pink Floyd'));
        expect(trackResult.coverUrl, isNotEmpty);
        expect(trackResult.track, isNotNull);
        expect(trackResult.album, isNull);
        expect(trackResult.artist, isNull);
      });
    });

    group('edge cases', () {
      test('handles empty catalog', () {
        final results = searchService.search(
          query: 'Beatles',
          artists: [],
          albums: [],
          tracks: [],
        );

        expect(results, isEmpty);
      });

      test('handles very short query', () {
        final results = searchService.search(
          query: 'a',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        // Should still work but may return many results
        expect(results, isA<List<SearchResult>>());
      });

      test('limits number of results', () {
        final results = searchService.search(
          query: 'The',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
          maxResults: 5,
        );

        expect(results.length, lessThanOrEqualTo(5));
      });

      test('minimum score threshold filters weak matches', () {
        final results = searchService.search(
          query: 'xyz123',
          artists: testArtists,
          albums: testAlbums,
          tracks: testTracks,
        );

        // Should not match anything with such unrelated query
        expect(results, isEmpty);
      });
    });
  });
}
