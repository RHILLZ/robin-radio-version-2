import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

/// Statistics about the audio cache
class CacheStats {
  final int trackCount;
  final int totalSizeBytes;

  const CacheStats({
    required this.trackCount,
    required this.totalSizeBytes,
  });

  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Metadata for a cached track
class CachedTrackInfo {
  final String trackId;
  final String filePath;
  final int sizeBytes;
  final DateTime cachedAt;

  const CachedTrackInfo({
    required this.trackId,
    required this.filePath,
    required this.sizeBytes,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
        'trackId': trackId,
        'filePath': filePath,
        'sizeBytes': sizeBytes,
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory CachedTrackInfo.fromJson(Map<String, dynamic> json) {
    return CachedTrackInfo(
      trackId: json['trackId'] as String,
      filePath: json['filePath'] as String,
      sizeBytes: json['sizeBytes'] as int,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }
}

/// Service for managing offline audio cache
///
/// Implements LRU cache eviction when max tracks or size is exceeded.
/// Caches audio files to local storage for offline playback.
class CacheService {
  final http.Client _httpClient;
  final int maxCachedTracks;
  final int maxCacheSizeBytes;

  // In-memory index of cached tracks (loaded from disk on init)
  final Map<String, CachedTrackInfo> _cacheIndex = {};
  Directory? _cacheDir;
  bool _initialized = false;

  CacheService({
    http.Client? httpClient,
    this.maxCachedTracks = 20,
    this.maxCacheSizeBytes = 500 * 1024 * 1024, // 500MB default
  }) : _httpClient = httpClient ?? http.Client();

  /// Initializes the cache service (ensures cache directory exists)
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final appDir = await getApplicationCacheDirectory();
    _cacheDir = Directory('${appDir.path}/audio_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }

    await _loadIndex();
    _initialized = true;
  }

  /// Loads the cache index from disk
  Future<void> _loadIndex() async {
    final indexFile = File('${_cacheDir!.path}/index.json');
    if (await indexFile.exists()) {
      try {
        final content = await indexFile.readAsString();
        final List<dynamic> items = json.decode(content);
        for (final item in items) {
          final info = CachedTrackInfo.fromJson(item);
          // Verify file still exists
          if (await File(info.filePath).exists()) {
            _cacheIndex[info.trackId] = info;
          }
        }
      } catch (_) {
        // Index corrupted, start fresh
        _cacheIndex.clear();
      }
    }
  }

  /// Saves the cache index to disk
  Future<void> _saveIndex() async {
    final indexFile = File('${_cacheDir!.path}/index.json');
    final items = _cacheIndex.values.map((i) => i.toJson()).toList();
    await indexFile.writeAsString(json.encode(items));
  }

  /// Gets the local URL for a cached track, or null if not cached
  Future<String?> getCachedUrl(Track track) async {
    await _ensureInitialized();

    final info = _cacheIndex[track.id];
    if (info == null) return null;

    // Verify file still exists
    final file = File(info.filePath);
    if (!await file.exists()) {
      _cacheIndex.remove(track.id);
      await _saveIndex();
      return null;
    }

    return info.filePath;
  }

  /// Checks if a track is cached
  Future<bool> isCached(Track track) async {
    final url = await getCachedUrl(track);
    return url != null;
  }

  /// Caches a track for offline playback
  ///
  /// Downloads the audio file and stores it locally.
  /// Handles eviction if cache limits are exceeded.
  Future<void> cacheTrack(Track track) async {
    await _ensureInitialized();

    // Skip if already cached
    if (await isCached(track)) return;

    try {
      // Download the audio file
      final response = await _httpClient.get(Uri.parse(track.audioUrl));
      if (response.statusCode != 200) return;

      // Save to cache directory
      final filename = _sanitizeFilename(track.id);
      final filePath = '${_cacheDir!.path}/$filename.mp3';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Add to index
      _cacheIndex[track.id] = CachedTrackInfo(
        trackId: track.id,
        filePath: filePath,
        sizeBytes: response.bodyBytes.length,
        cachedAt: DateTime.now(),
      );

      // Evict old tracks if needed
      await _evictIfNeeded();

      await _saveIndex();
    } catch (_) {
      // Silently fail on cache errors
    }
  }

  /// Evicts oldest tracks if cache limits are exceeded
  Future<void> _evictIfNeeded() async {
    // Sort by cache time (oldest first)
    final sortedEntries = _cacheIndex.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

    // Evict if count exceeded
    while (_cacheIndex.length > maxCachedTracks && sortedEntries.isNotEmpty) {
      final oldest = sortedEntries.removeAt(0);
      await _evictTrack(oldest.key);
    }

    // Evict if size exceeded
    int totalSize = _cacheIndex.values.fold(0, (sum, i) => sum + i.sizeBytes);
    while (totalSize > maxCacheSizeBytes && sortedEntries.isNotEmpty) {
      final oldest = sortedEntries.removeAt(0);
      totalSize -= oldest.value.sizeBytes;
      await _evictTrack(oldest.key);
    }
  }

  /// Evicts a single track from the cache
  Future<void> _evictTrack(String trackId) async {
    final info = _cacheIndex.remove(trackId);
    if (info != null) {
      final file = File(info.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Clears all cached tracks
  Future<void> clearCache() async {
    await _ensureInitialized();

    for (final info in _cacheIndex.values) {
      final file = File(info.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    _cacheIndex.clear();
    await _saveIndex();
  }

  /// Gets statistics about the cache
  Future<CacheStats> getCacheStats() async {
    await _ensureInitialized();

    final totalSize =
        _cacheIndex.values.fold(0, (sum, info) => sum + info.sizeBytes);

    return CacheStats(
      trackCount: _cacheIndex.length,
      totalSizeBytes: totalSize,
    );
  }

  /// Sanitizes a track ID for use as a filename
  String _sanitizeFilename(String id) {
    return id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
