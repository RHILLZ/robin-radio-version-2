import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/services/catalog_cache_service.dart';

// Reuse FakePathProviderPlatform pattern from cache_service_test.dart
class FakePathProviderPlatform extends PathProviderPlatform {
  final String tempPath;

  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;

  @override
  Future<String?> getApplicationCachePath() async => tempPath;
}

void main() {
  late CatalogCacheService cacheService;
  late Directory tempDir;

  const testArtist = Artist(
    id: 'artist1',
    name: 'Test Artist',
    storagePath: 'Artists/Test Artist',
    albumCount: 1,
  );

  const testAlbum = Album(
    id: 'album1',
    title: 'Test Album',
    artistId: 'artist1',
    artistName: 'Test Artist',
    coverUrl: 'https://example.com/cover.jpg',
    storagePath: 'Artists/Test Artist/Test Album',
    trackCount: 1,
  );

  const testTrack = Track(
    id: 'track1',
    title: 'Test Track',
    albumId: 'album1',
    albumTitle: 'Test Album',
    artistName: 'Test Artist',
    trackNumber: 1,
    audioUrl: 'https://example.com/track.mp3',
    coverUrl: 'https://example.com/cover.jpg',
    storagePath: 'Artists/Test Artist/Test Album/01 Test Track.mp3',
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('catalog_cache_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
    cacheService = CatalogCacheService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CatalogCacheService', () {
    test('saves and loads catalog data correctly (round-trip)', () async {
      await cacheService.saveCatalog(
        artists: [testArtist],
        albums: [testAlbum],
        tracks: [testTrack],
      );

      final cached = await cacheService.loadCatalog();

      expect(cached, isNotNull);
      expect(cached!.artists.length, equals(1));
      expect(cached.artists.first.id, equals('artist1'));
      expect(cached.artists.first.name, equals('Test Artist'));
      expect(cached.albums.length, equals(1));
      expect(cached.albums.first.id, equals('album1'));
      expect(cached.albums.first.title, equals('Test Album'));
      expect(cached.tracks.length, equals(1));
      expect(cached.tracks.first.id, equals('track1'));
      expect(cached.tracks.first.title, equals('Test Track'));
    });

    test('returns null when no cache file exists', () async {
      final cached = await cacheService.loadCatalog();
      expect(cached, isNull);
    });

    test('returns null and deletes file when cache is corrupted', () async {
      // Write garbage to the cache file
      final cacheFile = File('${tempDir.path}/catalog_cache.json');
      await cacheFile.writeAsString('not valid json {{{');

      final cached = await cacheService.loadCatalog();

      expect(cached, isNull);
      // File should be deleted after corruption detected
      expect(await cacheFile.exists(), isFalse);
    });

    test('clearCache deletes the cache file', () async {
      await cacheService.saveCatalog(
        artists: [testArtist],
        albums: [testAlbum],
        tracks: [testTrack],
      );

      // Verify cache exists
      final cachedBefore = await cacheService.loadCatalog();
      expect(cachedBefore, isNotNull);

      await cacheService.clearCache();

      final cachedAfter = await cacheService.loadCatalog();
      expect(cachedAfter, isNull);
    });

    test('cache persists across service instances (no session token)', () async {
      // Save with one instance
      await cacheService.saveCatalog(
        artists: [testArtist],
        albums: [testAlbum],
        tracks: [testTrack],
      );

      // Load with a completely new instance (simulating app restart)
      final newService = CatalogCacheService();
      final cached = await newService.loadCatalog();

      expect(cached, isNotNull);
      expect(cached!.albums.length, equals(1));
      expect(cached.albums.first.title, equals('Test Album'));
    });
  });
}
