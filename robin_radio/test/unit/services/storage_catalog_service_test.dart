import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:robin_radio/services/storage_catalog_service.dart';

import 'storage_catalog_service_test.mocks.dart';

@GenerateMocks([FirebaseStorage, Reference, ListResult])
void main() {
  late MockFirebaseStorage mockStorage;
  late MockReference mockRootRef;
  late StorageCatalogService service;

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockRootRef = MockReference();
    service = StorageCatalogService(storage: mockStorage);
  });

  group('StorageCatalogService', () {
    test('isLoaded returns false before loadCatalog', () {
      expect(service.isLoaded, isFalse);
    });

    test('getArtists returns empty list before loadCatalog', () {
      expect(service.getArtists(), isEmpty);
    });

    test('getAlbums returns empty list before loadCatalog', () {
      expect(service.getAlbums(), isEmpty);
    });

    test('getTracks returns empty list before loadCatalog', () {
      expect(service.getTracks(), isEmpty);
    });

    group('loadCatalog', () {
      test('scans Artist folder structure and creates catalog', () async {
        // Setup mock structure:
        // Artist/
        //   TestArtist/
        //     TestAlbum/
        //       TestAlbum.jpg
        //       01 Song One.mp3

        final mockArtistRef = MockReference();
        final mockAlbumRef = MockReference();
        final mockCoverRef = MockReference();
        final mockTrackRef = MockReference();

        final mockArtistResult = MockListResult();
        final mockAlbumResult = MockListResult();
        final mockAlbumContentsResult = MockListResult();

        // Root ref
        when(mockStorage.ref('Artist/')).thenReturn(mockRootRef);
        when(mockRootRef.listAll()).thenAnswer((_) async => mockArtistResult);
        when(mockArtistResult.prefixes).thenReturn([mockArtistRef]);

        // Artist ref
        when(mockArtistRef.name).thenReturn('TestArtist');
        when(mockArtistRef.fullPath).thenReturn('Artist/TestArtist');
        when(mockArtistRef.listAll()).thenAnswer((_) async => mockAlbumResult);
        when(mockAlbumResult.prefixes).thenReturn([mockAlbumRef]);

        // Album ref
        when(mockAlbumRef.name).thenReturn('TestAlbum');
        when(mockAlbumRef.fullPath).thenReturn('Artist/TestArtist/TestAlbum');
        when(mockAlbumRef.listAll())
            .thenAnswer((_) async => mockAlbumContentsResult);
        when(mockAlbumContentsResult.items)
            .thenReturn([mockCoverRef, mockTrackRef]);

        // Cover ref
        when(mockCoverRef.name).thenReturn('TestAlbum.jpg');
        when(mockCoverRef.getDownloadURL())
            .thenAnswer((_) async => 'https://example.com/cover.jpg');

        // Track ref
        when(mockTrackRef.name).thenReturn('01 Song One.mp3');
        when(mockTrackRef.fullPath)
            .thenReturn('Artist/TestArtist/TestAlbum/01 Song One.mp3');
        when(mockTrackRef.getDownloadURL())
            .thenAnswer((_) async => 'https://example.com/song.mp3');

        // Execute
        final result = await service.loadCatalog();

        // Verify
        expect(service.isLoaded, isTrue);

        expect(result.artists.length, equals(1));
        expect(result.artists.first.name, equals('TestArtist'));
        expect(result.artists.first.albumCount, equals(1));

        expect(result.albums.length, equals(1));
        expect(result.albums.first.title, equals('TestAlbum'));
        expect(result.albums.first.artistName, equals('TestArtist'));
        expect(
          result.albums.first.coverUrl,
          equals('https://example.com/cover.jpg'),
        );
        expect(result.albums.first.trackCount, equals(1));

        expect(result.tracks.length, equals(1));
        expect(result.tracks.first.title, equals('Song One'));
        expect(result.tracks.first.trackNumber, equals(1));
        expect(result.tracks.first.artistName, equals('TestArtist'));
        expect(result.tracks.first.albumTitle, equals('TestAlbum'));
        expect(
          result.tracks.first.audioUrl,
          equals('https://example.com/song.mp3'),
        );
        expect(
          result.tracks.first.coverUrl,
          equals('https://example.com/cover.jpg'),
        );
      });

      test('handles empty catalog gracefully', () async {
        final mockEmptyResult = MockListResult();

        when(mockStorage.ref('Artist/')).thenReturn(mockRootRef);
        when(mockRootRef.listAll()).thenAnswer((_) async => mockEmptyResult);
        when(mockEmptyResult.prefixes).thenReturn([]);

        final result = await service.loadCatalog();

        expect(service.isLoaded, isTrue);
        expect(result.artists, isEmpty);
        expect(result.albums, isEmpty);
        expect(result.tracks, isEmpty);
      });
    });

    group('getTracksForAlbum', () {
      test('returns tracks sorted by track number', () async {
        // Setup mock with multiple tracks out of order
        final mockArtistRef = MockReference();
        final mockAlbumRef = MockReference();
        final mockTrack1Ref = MockReference();
        final mockTrack2Ref = MockReference();
        final mockTrack3Ref = MockReference();

        final mockArtistResult = MockListResult();
        final mockAlbumResult = MockListResult();
        final mockAlbumContentsResult = MockListResult();

        when(mockStorage.ref('Artist/')).thenReturn(mockRootRef);
        when(mockRootRef.listAll()).thenAnswer((_) async => mockArtistResult);
        when(mockArtistResult.prefixes).thenReturn([mockArtistRef]);

        when(mockArtistRef.name).thenReturn('Artist');
        when(mockArtistRef.fullPath).thenReturn('Artist/Artist');
        when(mockArtistRef.listAll()).thenAnswer((_) async => mockAlbumResult);
        when(mockAlbumResult.prefixes).thenReturn([mockAlbumRef]);

        when(mockAlbumRef.name).thenReturn('Album');
        when(mockAlbumRef.fullPath).thenReturn('Artist/Artist/Album');
        when(mockAlbumRef.listAll())
            .thenAnswer((_) async => mockAlbumContentsResult);
        when(mockAlbumContentsResult.items)
            .thenReturn([mockTrack3Ref, mockTrack1Ref, mockTrack2Ref]);

        // Tracks added out of order
        when(mockTrack3Ref.name).thenReturn('03 Third.mp3');
        when(mockTrack3Ref.fullPath)
            .thenReturn('Artist/Artist/Album/03 Third.mp3');
        when(mockTrack3Ref.getDownloadURL())
            .thenAnswer((_) async => 'https://example.com/3.mp3');

        when(mockTrack1Ref.name).thenReturn('01 First.mp3');
        when(mockTrack1Ref.fullPath)
            .thenReturn('Artist/Artist/Album/01 First.mp3');
        when(mockTrack1Ref.getDownloadURL())
            .thenAnswer((_) async => 'https://example.com/1.mp3');

        when(mockTrack2Ref.name).thenReturn('02 Second.mp3');
        when(mockTrack2Ref.fullPath)
            .thenReturn('Artist/Artist/Album/02 Second.mp3');
        when(mockTrack2Ref.getDownloadURL())
            .thenAnswer((_) async => 'https://example.com/2.mp3');

        await service.loadCatalog();

        final albumId = Uri.encodeComponent('Artist/Album');
        final tracks = service.getTracksForAlbum(albumId);

        expect(tracks.length, equals(3));
        expect(tracks[0].trackNumber, equals(1));
        expect(tracks[0].title, equals('First'));
        expect(tracks[1].trackNumber, equals(2));
        expect(tracks[1].title, equals('Second'));
        expect(tracks[2].trackNumber, equals(3));
        expect(tracks[2].title, equals('Third'));
      });
    });

    group('getAlbumsForArtist', () {
      test('filters albums by artist id', () async {
        // Create a multi-artist catalog mock
        final mockArtist1Ref = MockReference();
        final mockArtist2Ref = MockReference();
        final mockAlbum1Ref = MockReference();
        final mockAlbum2Ref = MockReference();

        final mockArtistResult = MockListResult();
        final mockArtist1AlbumResult = MockListResult();
        final mockArtist2AlbumResult = MockListResult();
        final mockEmptyContents = MockListResult();

        when(mockStorage.ref('Artist/')).thenReturn(mockRootRef);
        when(mockRootRef.listAll()).thenAnswer((_) async => mockArtistResult);
        when(mockArtistResult.prefixes)
            .thenReturn([mockArtist1Ref, mockArtist2Ref]);

        // Artist 1
        when(mockArtist1Ref.name).thenReturn('ArtistOne');
        when(mockArtist1Ref.fullPath).thenReturn('Artist/ArtistOne');
        when(mockArtist1Ref.listAll())
            .thenAnswer((_) async => mockArtist1AlbumResult);
        when(mockArtist1AlbumResult.prefixes).thenReturn([mockAlbum1Ref]);

        when(mockAlbum1Ref.name).thenReturn('AlbumA');
        when(mockAlbum1Ref.fullPath).thenReturn('Artist/ArtistOne/AlbumA');
        when(mockAlbum1Ref.listAll())
            .thenAnswer((_) async => mockEmptyContents);

        // Artist 2
        when(mockArtist2Ref.name).thenReturn('ArtistTwo');
        when(mockArtist2Ref.fullPath).thenReturn('Artist/ArtistTwo');
        when(mockArtist2Ref.listAll())
            .thenAnswer((_) async => mockArtist2AlbumResult);
        when(mockArtist2AlbumResult.prefixes).thenReturn([mockAlbum2Ref]);

        when(mockAlbum2Ref.name).thenReturn('AlbumB');
        when(mockAlbum2Ref.fullPath).thenReturn('Artist/ArtistTwo/AlbumB');
        when(mockAlbum2Ref.listAll())
            .thenAnswer((_) async => mockEmptyContents);

        when(mockEmptyContents.items).thenReturn([]);

        await service.loadCatalog();

        final artist1Id = Uri.encodeComponent('ArtistOne');
        final artist1Albums = service.getAlbumsForArtist(artist1Id);

        expect(artist1Albums.length, equals(1));
        expect(artist1Albums.first.title, equals('AlbumA'));

        final artist2Id = Uri.encodeComponent('ArtistTwo');
        final artist2Albums = service.getAlbumsForArtist(artist2Id);

        expect(artist2Albums.length, equals(1));
        expect(artist2Albums.first.title, equals('AlbumB'));
      });
    });
  });
}
