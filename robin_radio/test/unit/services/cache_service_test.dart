import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:robin_radio/models/models.dart';
import 'package:robin_radio/services/cache_service.dart';

import 'cache_service_test.mocks.dart';

// Mock path_provider for testing
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

@GenerateMocks([http.Client])
void main() {
  late CacheService cacheService;
  late MockClient mockHttpClient;
  late Directory tempDir;

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

  setUp(() async {
    mockHttpClient = MockClient();

    // Create a temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('cache_test');

    // Set up the path provider mock
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    cacheService = CacheService(
      httpClient: mockHttpClient,
      maxCachedTracks: 5,
      maxCacheSizeBytes: 50 * 1024 * 1024, // 50MB for testing
    );
  });

  tearDown(() async {
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CacheService', () {
    group('getCachedUrl', () {
      test('returns null for uncached track', () async {
        final cachedUrl = await cacheService.getCachedUrl(testTrack);
        expect(cachedUrl, isNull);
      });

      test('returns local path for cached track', () async {
        // Mock successful download
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response.bytes(
            List.filled(1024, 0), // 1KB of data
            200,
          ),
        );

        await cacheService.cacheTrack(testTrack);
        final cachedUrl = await cacheService.getCachedUrl(testTrack);

        expect(cachedUrl, isNotNull);
        expect(cachedUrl, contains(testTrack.id));
      });
    });

    group('cacheTrack', () {
      test('downloads and stores track locally', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response.bytes(
            List.filled(1024, 0), // 1KB of data
            200,
          ),
        );

        await cacheService.cacheTrack(testTrack);

        verify(mockHttpClient.get(Uri.parse(testTrack.audioUrl))).called(1);

        final cachedUrl = await cacheService.getCachedUrl(testTrack);
        expect(cachedUrl, isNotNull);
      });

      test('does not re-download already cached track', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response.bytes(
            List.filled(1024, 0),
            200,
          ),
        );

        await cacheService.cacheTrack(testTrack);
        await cacheService.cacheTrack(testTrack);

        // Should only download once
        verify(mockHttpClient.get(any)).called(1);
      });

      test('handles download failure gracefully', () async {
        when(mockHttpClient.get(any)).thenThrow(Exception('Network error'));

        // Should not throw
        await expectLater(
          cacheService.cacheTrack(testTrack),
          completes,
        );

        // Track should not be cached
        final cachedUrl = await cacheService.getCachedUrl(testTrack);
        expect(cachedUrl, isNull);
      });
    });

    group('eviction', () {
      test('evicts oldest tracks when max count exceeded', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response.bytes(
            List.filled(1024, 0),
            200,
          ),
        );

        // Cache more tracks than maxCachedTracks (5)
        for (var i = 0; i < 7; i++) {
          final track = testTrack.copyWith(
            id: 'track-$i',
            audioUrl: 'https://example.com/song$i.mp3',
          );
          await cacheService.cacheTrack(track);
        }

        // First two tracks should be evicted (oldest)
        final track0Cached = await cacheService.getCachedUrl(
          testTrack.copyWith(id: 'track-0'),
        );
        final track1Cached = await cacheService.getCachedUrl(
          testTrack.copyWith(id: 'track-1'),
        );

        // Recent tracks should still be cached
        final track6Cached = await cacheService.getCachedUrl(
          testTrack.copyWith(id: 'track-6'),
        );

        expect(track0Cached, isNull);
        expect(track1Cached, isNull);
        expect(track6Cached, isNotNull);
      });
    });

    group('isCached', () {
      test('returns false for uncached track', () async {
        final isCached = await cacheService.isCached(testTrack);
        expect(isCached, isFalse);
      });

      test('returns true for cached track', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response.bytes(
            List.filled(1024, 0),
            200,
          ),
        );

        await cacheService.cacheTrack(testTrack);
        final isCached = await cacheService.isCached(testTrack);

        expect(isCached, isTrue);
      });
    });

    group('clearCache', () {
      test('removes all cached tracks', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response.bytes(
            List.filled(1024, 0),
            200,
          ),
        );

        await cacheService.cacheTrack(testTrack);
        expect(await cacheService.isCached(testTrack), isTrue);

        await cacheService.clearCache();

        expect(await cacheService.isCached(testTrack), isFalse);
      });
    });

    group('getCacheStats', () {
      test('returns zero stats for empty cache', () async {
        final stats = await cacheService.getCacheStats();

        expect(stats.trackCount, equals(0));
        expect(stats.totalSizeBytes, equals(0));
      });

      test('returns correct stats after caching', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response.bytes(
            List.filled(1024, 0), // 1KB
            200,
          ),
        );

        await cacheService.cacheTrack(testTrack);
        final stats = await cacheService.getCacheStats();

        expect(stats.trackCount, equals(1));
        expect(stats.totalSizeBytes, equals(1024));
      });
    });
  });
}
