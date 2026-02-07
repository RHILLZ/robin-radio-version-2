import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

/// Persists catalog metadata (artists, albums, tracks) to a JSON file on disk.
///
/// The cache uses a session token: when the app starts, it generates a new token.
/// If the stored token doesn't match the current session, the cache is considered
/// stale and ignored. This means the cache is only used within the same app session
/// (i.e., between hot reloads or navigations, not across cold restarts).
class CatalogCacheService {
  static const String _cacheFileName = 'catalog_cache.json';

  final String _sessionToken;
  Directory? _cacheDir;
  bool _initialized = false;

  CatalogCacheService({required String sessionToken})
      : _sessionToken = sessionToken;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _cacheDir = await getApplicationCacheDirectory();
    _initialized = true;
  }

  File get _cacheFile => File('${_cacheDir!.path}/$_cacheFileName');

  /// Saves the catalog to disk with the current session token.
  Future<void> saveCatalog({
    required List<Artist> artists,
    required List<Album> albums,
    required List<Track> tracks,
  }) async {
    await _ensureInitialized();

    final data = {
      'sessionToken': _sessionToken,
      'cachedAt': DateTime.now().toIso8601String(),
      'artists': artists.map((a) => a.toJson()).toList(),
      'albums': albums.map((a) => a.toJson()).toList(),
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };

    await _cacheFile.writeAsString(json.encode(data));
  }

  /// Loads the catalog from disk if the session token matches.
  ///
  /// Returns null if:
  /// - No cache file exists
  /// - The session token doesn't match (app was restarted)
  /// - The cache file is corrupted
  Future<CachedCatalog?> loadCatalog() async {
    await _ensureInitialized();

    if (!await _cacheFile.exists()) return null;

    try {
      final content = await _cacheFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      // Check session token — reject cache from previous sessions
      final storedToken = data['sessionToken'] as String?;
      if (storedToken != _sessionToken) return null;

      final artists = (data['artists'] as List)
          .map((j) => Artist.fromJson(j as Map<String, dynamic>))
          .toList();
      final albums = (data['albums'] as List)
          .map((j) => Album.fromJson(j as Map<String, dynamic>))
          .toList();
      final tracks = (data['tracks'] as List)
          .map((j) => Track.fromJson(j as Map<String, dynamic>))
          .toList();

      return CachedCatalog(artists: artists, albums: albums, tracks: tracks);
    } catch (_) {
      // Cache corrupted, delete it
      await clearCache();
      return null;
    }
  }

  /// Deletes the cache file.
  Future<void> clearCache() async {
    await _ensureInitialized();
    if (await _cacheFile.exists()) {
      await _cacheFile.delete();
    }
  }
}

/// Holds catalog data loaded from cache.
class CachedCatalog {
  final List<Artist> artists;
  final List<Album> albums;
  final List<Track> tracks;

  const CachedCatalog({
    required this.artists,
    required this.albums,
    required this.tracks,
  });
}
