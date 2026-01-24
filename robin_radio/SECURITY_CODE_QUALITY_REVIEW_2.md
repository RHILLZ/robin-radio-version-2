# Robin Radio 2.0 - Second Pass Security & Code Quality Review

**Review Date**: January 18, 2026
**Scope**: lib/services/audio_service.dart, cache_service.dart, lib/providers/playback_provider.dart, catalog_provider.dart
**Status**: COMPREHENSIVE REVIEW COMPLETED

---

## Executive Summary

This second pass review identified **5 High-Severity**, **4 Medium-Severity**, and **3 Low-Severity** issues across the Robin Radio Flutter app. The previous URL scheme validation in audio_service.dart successfully mitigated URL injection risks, but several additional security and code quality vulnerabilities remain, particularly in error handling, null safety, and resource management.

**Critical Findings**: Network request error handling gaps, uncaught Firebase exceptions, missing URL validation on cover images, and potential memory leaks from background cache operations.

---

## Critical Issues Found

### 1. SECURITY HIGH - Uncaught Firebase Network Exceptions in StorageCatalogService
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/services/storage_catalog_service.dart`
**Lines**: 51-81
**Severity**: HIGH
**Type**: Error Handling / Availability

**Issue**:
```dart
final artistResult = await artistRef.listAll();  // Line 52
final albumResult = await artistPrefix.listAll();  // Line 58
final albumContents = await albumPrefix.listAll();  // Line 65
coverUrl = await item.getDownloadURL();  // Line 76
final audioUrl = await item.getDownloadURL();  // Line 81
```

The `loadCatalog()` method has **no try-catch blocks** around Firebase Storage API calls. This means:
- Network errors will crash the app
- Firebase authentication failures will crash the app
- Storage permission errors will crash the app
- The `loadCatalog()` future will complete with an unhandled exception, potentially leaving the app in an inconsistent state

**Attack Vector**: A user with no internet connection will experience an app crash instead of graceful degradation.

**Impact**:
- App becomes unstable on poor network conditions
- Offline users cannot use the app
- Catalog loading failure leaves app in undefined state

**Remediation**:
```dart
@override
Future<({List<Artist> artists, List<Album> albums, List<Track> tracks})>
    loadCatalog() async {
  final artists = <Artist>[];
  final albums = <Album>[];
  final tracks = <Track>[];

  try {
    // List all artists under "Artist/" prefix
    final artistRef = _storage.ref('Artist/');
    final artistResult = await artistRef.listAll();

    for (final artistPrefix in artistResult.prefixes) {
      try {
        final artistName = artistPrefix.name;

        // List all albums for this artist
        final albumResult = await artistPrefix.listAll();
        final artistAlbums = <Album>[];

        for (final albumPrefix in albumResult.prefixes) {
          try {
            final albumTitle = albumPrefix.name;

            // List all files in the album folder
            final albumContents = await albumPrefix.listAll();

            // Find cover image and audio tracks
            String? coverUrl;
            final albumTracks = <Track>[];

            for (final item in albumContents.items) {
              final filename = item.name.toLowerCase();

              try {
                if (filename.endsWith('.jpg') || filename.endsWith('.png')) {
                  coverUrl = await item.getDownloadURL();
                } else if (filename.endsWith('.mp3') ||
                    filename.endsWith('.m4a') ||
                    filename.endsWith('.aac')) {
                  final audioUrl = await item.getDownloadURL();
                  final track = Track.fromStorageItem(
                    item,
                    artistName,
                    albumTitle,
                    audioUrl,
                    '',
                  );
                  albumTracks.add(track);
                }
              } catch (e) {
                // Skip individual tracks that fail to load
                print('Failed to load track ${item.name}: $e');
              }
            }

            // Use placeholder if no cover found
            coverUrl ??= '';

            // Update tracks with cover URL
            final tracksWithCover = albumTracks
                .map((track) => track.copyWith(coverUrl: coverUrl))
                .toList();

            // Create album
            final album = Album.fromStoragePrefix(
              albumPrefix,
              artistName,
              coverUrl,
              tracksWithCover.length,
            );

            artistAlbums.add(album);
            albums.add(album);
            tracks.addAll(tracksWithCover);
          } catch (e) {
            // Skip individual albums that fail to load
            print('Failed to load album ${albumPrefix.name} for $artistName: $e');
          }
        }

        // Create artist with album count
        final artist = Artist.fromStoragePrefix(artistPrefix, artistAlbums.length);
        artists.add(artist);
      } catch (e) {
        // Skip individual artists that fail to load
        print('Failed to load artist ${artistPrefix.name}: $e');
      }
    }

    // Cache results
    _artists = artists;
    _albums = albums;
    _tracks = tracks;
    _isLoaded = true;

    return (artists: artists, albums: albums, tracks: tracks);
  } catch (e) {
    // Log error but return partial results if some data was loaded
    print('Error loading catalog: $e');
    if (artists.isNotEmpty || albums.isNotEmpty || tracks.isNotEmpty) {
      _artists = artists;
      _albums = albums;
      _tracks = tracks;
      _isLoaded = true;
      return (artists: artists, albums: albums, tracks: tracks);
    }
    rethrow; // Re-throw if completely failed
  }
}
```

---

### 2. SECURITY HIGH - Missing URL Validation for Cover Images
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/services/audio_service.dart`
**Line**: 166
**Severity**: HIGH
**Type**: Input Validation / Injection

**Issue**:
```dart
artUri: track.coverUrl.isNotEmpty ? Uri.parse(track.coverUrl) : null,  // Line 166
```

Cover URLs are not validated before being passed to the media metadata. While audio_service.dart validates `audioUrl`, the `coverUrl` is parsed without scheme validation. An attacker could craft a malicious coverUrl (e.g., `javascript://`, `data://`, etc.) that might be exploited in UI rendering or background playback metadata.

**Impact**:
- Potential XSS if coverUrl is ever rendered in a WebView or evaluated
- Metadata injection attacks
- Potential for file:// scheme access to local files

**Remediation**:
```dart
// In audio_service.dart, add helper method
String _validateImageUrl(String url) {
  if (url.isEmpty) return url;

  try {
    final uri = Uri.parse(url);
    // Only allow https, http, or file schemes
    if (uri.scheme != 'https' && uri.scheme != 'http' && uri.scheme != 'file') {
      throw AudioPlaybackException(
        'Invalid image URL scheme: ${uri.scheme}',
      );
    }
    return url;
  } catch (e) {
    throw AudioPlaybackException('Invalid image URL format: $url');
  }
}

// Update _playCurrentTrack
artUri: track.coverUrl.isNotEmpty
    ? Uri.parse(_validateImageUrl(track.coverUrl))
    : null,
```

---

### 3. SECURITY HIGH - Uncaught HTTP Exception in Cache Service
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/services/cache_service.dart`
**Line**: 157
**Severity**: HIGH
**Type**: Error Handling

**Issue**:
```dart
try {
  // Download the audio file
  final response = await _httpClient.get(Uri.parse(track.audioUrl));
  if (response.statusCode != 200) return;  // Line 158

  // Save to cache directory
  final filename = _sanitizeFilename(track.id);
  final filePath = '${_cacheDir!.path}/$filename.mp3';
  // ... rest of file write operations
} catch (_) {
  // Silently fail on cache errors  (Line 178-180)
}
```

**Problems**:
1. **Silent failure with overly broad catch**: The `catch (_)` swallows ALL exceptions including:
   - HTTP network timeout (SocketException)
   - IOException when writing to disk
   - Permission errors
   - Out of disk space errors

2. **No partial file cleanup**: If an exception occurs after `file.writeAsBytes()` starts, the partial file remains in cache directory, wasting disk space.

3. **No timeout handling**: HTTP GET has no timeout, could hang indefinitely on slow networks.

**Impact**:
- Cache directory fills with partial/corrupt files
- No visibility into caching failures for debugging
- Potential disk space exhaustion
- Indefinite network hangs

**Remediation**:
```dart
Future<void> cacheTrack(Track track) async {
  await _ensureInitialized();

  // Skip if already cached
  if (await isCached(track)) return;

  String? tempFilePath;
  try {
    // Parse and validate URL
    final Uri uri;
    try {
      uri = Uri.parse(track.audioUrl);
      if (uri.scheme != 'https' && uri.scheme != 'http') {
        return; // Skip caching for non-http URLs
      }
    } catch (e) {
      print('Invalid audio URL for caching: $e');
      return;
    }

    // Download with timeout
    final response = await _httpClient.get(uri)
        .timeout(const Duration(minutes: 5));

    if (response.statusCode != 200) {
      print('Failed to download track ${track.id}: status ${response.statusCode}');
      return;
    }

    // Save to temporary file first
    final filename = _sanitizeFilename(track.id);
    tempFilePath = '${_cacheDir!.path}/${filename}_temp.mp3';
    final tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(response.bodyBytes);

    // Verify file was written correctly
    if (!await tempFile.exists()) {
      throw IOException('Failed to write cache file');
    }

    // Move temp file to final location
    final finalPath = '${_cacheDir!.path}/$filename.mp3';
    final finalFile = await tempFile.rename(finalPath);

    // Add to index
    _cacheIndex[track.id] = CachedTrackInfo(
      trackId: track.id,
      filePath: finalFile.path,
      sizeBytes: response.bodyBytes.length,
      cachedAt: DateTime.now(),
    );

    // Evict old tracks if needed
    await _evictIfNeeded();
    await _saveIndex();

  } on SocketException catch (e) {
    print('Network error caching track ${track.id}: $e');
    // Clean up temp file
    if (tempFilePath != null) {
      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) await tempFile.delete();
    }
  } on IOException catch (e) {
    print('IO error caching track ${track.id}: $e');
    // Clean up temp file
    if (tempFilePath != null) {
      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) await tempFile.delete();
    }
  } catch (e) {
    print('Unexpected error caching track ${track.id}: $e');
    // Clean up temp file
    if (tempFilePath != null) {
      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) await tempFile.delete();
    }
  }
}
```

---

### 4. SECURITY HIGH - Missing Null Check on CacheService in AudioService
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/services/audio_service.dart`
**Lines**: 135-140, 177
**Severity**: HIGH
**Type**: Null Safety

**Issue**:
```dart
if (_cacheService != null) {
  final cachedUrl = await _cacheService.getCachedUrl(track);  // Line 136
  if (cachedUrl != null) {
    audioUrl = cachedUrl;
  }
}

// Later:
if (_cacheService != null && !audioUrl.startsWith('/')) {
  _cacheService.cacheTrack(track);  // Line 179 - fire and forget, no await
}
```

**Problems**:
1. **Fire-and-forget coroutine**: `cacheTrack()` is called without `await`, meaning errors in caching are silently swallowed.
2. **Potential null dereference**: While null check exists, the pattern is fragile and could regress.
3. **No exception handling**: If `getCachedUrl()` or `cacheTrack()` throws, the entire playback fails silently.

**Impact**:
- Silent failures in cache operations
- Potential crashes from unhandled exceptions in background tasks
- Cache operations don't complete before playback ends

**Remediation**:
```dart
Future<void> _playCurrentTrackWithRetry({int maxRetries = 3}) async {
  int attempts = 0;

  while (attempts < maxRetries) {
    final track = _currentQueue?.currentTrack;
    if (track == null) return;

    try {
      // Check for cached version first
      String audioUrl = track.audioUrl;
      if (_cacheService != null) {
        try {
          final cachedUrl = await _cacheService.getCachedUrl(track);
          if (cachedUrl != null) {
            audioUrl = cachedUrl;
          }
        } catch (e) {
          print('Cache lookup failed: $e');
          // Continue with remote URL
        }
      }

      // Determine if we're using a local file or remote URL
      // Validate URL scheme for security (only allow https/http for remote)
      final Uri uri;
      if (audioUrl.startsWith('/')) {
        uri = Uri.file(audioUrl);
      } else {
        final parsed = Uri.parse(audioUrl);
        if (parsed.scheme != 'https' && parsed.scheme != 'http') {
          throw AudioPlaybackException(
            'Invalid audio URL scheme: ${parsed.scheme}',
          );
        }
        uri = parsed;
      }

      // Create audio source with MediaItem tag for background playback metadata
      final imageUri = track.coverUrl.isNotEmpty
          ? Uri.tryParse(track.coverUrl)
          : null;

      // Validate image URL scheme if present
      if (imageUri != null &&
          imageUri.scheme != 'https' &&
          imageUri.scheme != 'http' &&
          imageUri.scheme != 'file') {
        print('Invalid cover URL scheme: ${imageUri.scheme}');
      }

      final audioSource = AudioSource.uri(
        uri,
        tag: MediaItem(
          id: track.id,
          album: track.albumTitle,
          title: track.title,
          artist: track.artistName,
          artUri: imageUri != null
              ? (imageUri.scheme == 'https' || imageUri.scheme == 'http')
                  ? imageUri
                  : null
              : null,
          duration: track.duration != null
              ? Duration(seconds: track.duration!)
              : null,
        ),
      );

      await _player.setAudioSource(audioSource);
      await _player.play();

      // Cache the track in the background after starting playback
      if (_cacheService != null && !audioUrl.startsWith('/')) {
        // Only cache if we played from remote URL (not already cached)
        try {
          await _cacheService.cacheTrack(track);
        } catch (e) {
          print('Failed to cache track: $e');
          // Don't fail playback if caching fails
        }
      }
      return; // Success, exit the retry loop
    } on PlayerException {
      // Track failed to load, try to skip to next
      attempts++;
      if (_currentQueue != null && _currentQueue!.hasNext) {
        _currentQueue = _currentQueue!.copyWith(
          currentIndex: _currentQueue!.currentIndex + 1,
        );
        continue; // Try next track
      }
      // No more tracks, throw
      throw AudioPlaybackException(
        'Failed to play track: ${track.title}',
      );
    } on PlayerInterruptedException catch (e) {
      throw AudioPlaybackException(
        'Playback interrupted for: ${track.title}',
        cause: e,
      );
    }
  }

  throw AudioPlaybackException(
    'Failed to play after $maxRetries attempts',
  );
}
```

---

### 5. SECURITY HIGH - Connectivity Provider Silent Failure Pattern
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/providers/connectivity_provider.dart`
**Lines**: 10-18
**Severity**: HIGH
**Type**: Availability / Fault Tolerance

**Issue**:
```dart
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);

  return connectivityAsync.when(
    data: (results) => !results.contains(ConnectivityResult.none),
    loading: () => true, // Assume online while loading
    error: (_, __) => true, // Assume online on error  <-- PROBLEM
  );
});
```

**Problems**:
1. **Unsafe assumption on error**: When the connectivity plugin fails (e.g., permission denied, plugin not initialized), the app assumes online status.
2. **No error logging**: Connectivity errors are silently swallowed, making debugging impossible.
3. **Cascading failures**: App will attempt network operations during airplane mode if plugin fails.

**Impact**:
- During airplane mode with plugin error, app tries to stream audio over network
- Poor user experience when connectivity detection fails
- No visibility into connectivity subsystem failures

**Remediation**:
```dart
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged.handleError((error) {
    print('Connectivity plugin error: $error');
    // Gracefully degrade by assuming offline on error
    return [ConnectivityResult.none];
  });
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);

  return connectivityAsync.when(
    data: (results) => !results.contains(ConnectivityResult.none),
    loading: () => false, // Conservative: assume offline while loading
    error: (error, stackTrace) {
      print('Error detecting connectivity: $error\n$stackTrace');
      return false; // Conservative: assume offline on error
    },
  );
});

// Add explicit offline indicator provider
final offlineReasonProvider = Provider<String?>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);

  return connectivityAsync.when(
    data: (results) => results.contains(ConnectivityResult.none)
        ? 'No network connection'
        : null,
    loading: () => 'Checking network...',
    error: (error, _) => 'Network detection failed: $error',
  );
});
```

---

## Medium-Severity Issues

### 6. CODE QUALITY MEDIUM - Race Condition in PlaybackNotifier State Updates
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/providers/playback_provider.dart`
**Lines**: 81-102
**Severity**: MEDIUM
**Type**: Concurrency

**Issue**:
```dart
void _setupListeners() {
  _playerStateSubscription = _audioService.playerStateStream.listen((playerState) {
    state = state.copyWith(
      isPlaying: playerState.playing,
      isLoading: playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering,
    );

    // Auto-advance when track completes
    if (playerState.processingState == ProcessingState.completed) {
      _onTrackComplete();  // Calls skipNext() which also modifies state
    }
  });
}

void _onTrackComplete() {
  if (_audioService.hasNext) {
    skipNext();  // This modifies state asynchronously
  }
}

Future<void> skipNext() async {
  if (!state.hasNext) return;

  state = state.copyWith(isLoading: true, error: null);  // State modified here
  try {
    await _audioService.skipNext();  // Async operation
    _updateStateFromService();  // And here again
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: 'Failed to skip to next track: $e',
    );
  }
}
```

**Problem**:
- `_onTrackComplete()` calls `skipNext()` which is async
- `skipNext()` modifies state immediately, then awaits `_audioService.skipNext()`, then modifies state again
- Meanwhile, position/duration streams continue updating state
- Multiple rapid state updates could cause inconsistent UI state

**Impact**:
- UI flicker or jank during track transitions
- Potential state inconsistency where UI shows incorrect track
- Difficult race condition to debug

**Remediation**:
```dart
void _setupListeners() {
  _playerStateSubscription = _audioService.playerStateStream.listen((playerState) {
    state = state.copyWith(
      isPlaying: playerState.playing,
      isLoading: playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering,
    );

    // Auto-advance when track completes
    if (playerState.processingState == ProcessingState.completed) {
      _onTrackComplete();
    }
  });

  _positionSubscription = _audioService.positionStream.listen((position) {
    // Don't update position if we're in the middle of a state mutation
    if (!state.isLoading) {
      state = state.copyWith(position: position);
    }
  });

  _durationSubscription = _audioService.durationStream.listen((duration) {
    state = state.copyWith(duration: duration);
  });
}

void _onTrackComplete() {
  if (_audioService.hasNext) {
    skipNext();
  }
}

Future<void> skipNext() async {
  if (!state.hasNext) return;

  state = state.copyWith(isLoading: true, error: null);
  try {
    await _audioService.skipNext();
    // Single state update after async operation completes
    _updateStateFromService();
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: 'Failed to skip to next track: $e',
    );
  }
}
```

---

### 7. CODE QUALITY MEDIUM - Missing Bounds Validation in CatalogProvider
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/providers/catalog_provider.dart`
**Lines**: 75-85
**Severity**: MEDIUM
**Type**: Input Validation

**Issue**:
```dart
/// Gets albums for a specific artist
List<Album> getAlbumsForArtist(String artistId) {
  return state.albums.where((album) => album.artistId == artistId).toList();
}

/// Gets tracks for a specific album
List<Track> getTracksForAlbum(String albumId) {
  return state.tracks
      .where((track) => track.albumId == albumId)
      .toList()
    ..sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
}
```

**Problems**:
1. **No empty input validation**: `artistId` or `albumId` could be empty string, null (before null safety check), or malformed
2. **No null safety checks**: If artistId is empty string, returns all albums (logic error)
3. **Sorting side effect**: The `..sort()` mutates the returned list. While it's a new list, the pattern is unexpected.

**Impact**:
- Empty artistId returns all albums (data leakage)
- Confusing API contract
- Potential crashes if catalog not loaded

**Remediation**:
```dart
/// Gets albums for a specific artist
List<Album> getAlbumsForArtist(String artistId) {
  if (artistId.trim().isEmpty) {
    return [];
  }
  return state.albums.where((album) => album.artistId == artistId).toList();
}

/// Gets tracks for a specific album
List<Track> getTracksForAlbum(String albumId) {
  if (albumId.trim().isEmpty) {
    return [];
  }
  final tracks = state.tracks
      .where((track) => track.albumId == albumId)
      .toList();

  // Sort by track number
  tracks.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
  return tracks;
}
```

---

### 8. CODE QUALITY MEDIUM - Unhandled Exception in CatalogNotifier.loadCatalog()
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/providers/catalog_provider.dart`
**Lines**: 52-72
**Severity**: MEDIUM
**Type**: Error Handling

**Issue**:
```dart
Future<void> loadCatalog() async {
  if (state.isLoading) return;

  state = state.copyWith(isLoading: true, error: null);

  try {
    final result = await _catalogService.loadCatalog();
    state = CatalogState(
      artists: result.artists,
      albums: result.albums,
      tracks: result.tracks,
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: 'Failed to load catalog: $e',  // e includes stack trace in toString()
    );
  }
}
```

**Problems**:
1. **Generic error display**: The error message shows entire exception stack trace (including null pointers, Firebase details)
2. **isLoading flag not cleared if re-throwing**: If an exception propagates, `isLoading` remains true
3. **No retry mechanism**: Users can't retry failed loads without restarting app
4. **Swallows exception**: Original exception context is lost for debugging

**Impact**:
- Confusing error messages shown to user
- Potential information leakage (Firebase project IDs, paths)
- Poor UX with no recovery mechanism

**Remediation**:
```dart
Future<void> loadCatalog() async {
  if (state.isLoading) return;

  state = state.copyWith(isLoading: true, error: null);

  try {
    final result = await _catalogService.loadCatalog();
    state = CatalogState(
      artists: result.artists,
      albums: result.albums,
      tracks: result.tracks,
      isLoading: false,
    );
  } catch (e) {
    // Log full error for debugging
    print('Error loading catalog: $e');

    // Display user-friendly error
    String userMessage = 'Failed to load music catalog';
    if (e.toString().contains('network') || e.toString().contains('Network')) {
      userMessage = 'Network error. Please check your connection and try again.';
    } else if (e.toString().contains('permission') || e.toString().contains('Permission')) {
      userMessage = 'Permission denied. The app may not have storage access.';
    }

    state = state.copyWith(
      isLoading: false,
      error: userMessage,
    );
  }
}

/// Retry loading the catalog
Future<void> retry() async {
  await loadCatalog();
}
```

---

### 9. CODE QUALITY MEDIUM - Potential Memory Leak in Cache Index
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/services/cache_service.dart`
**Lines**: 69, 185-201
**Severity**: MEDIUM
**Type**: Memory Management

**Issue**:
```dart
final Map<String, CachedTrackInfo> _cacheIndex = {};  // Line 69 - never cleared

Future<void> _evictIfNeeded() async {
  // Sort by cache time (oldest first)
  final sortedEntries = _cacheIndex.entries.toList()  // Creates new list each time
    ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

  // Evict if count exceeded
  while (_cacheIndex.length > maxCachedTracks && sortedEntries.isNotEmpty) {
    final oldest = sortedEntries.removeAt(0);
    await _evictTrack(oldest.key);
  }
}
```

**Problems**:
1. **In-memory index never garbage collected**: The `_cacheIndex` map grows with app lifetime
2. **Sorting creates intermediate list**: Each eviction check creates a new sorted list (inefficient)
3. **No cache size limits on file system**: While eviction happens, no validation that actual files match index

**Impact**:
- Memory grows unbounded with number of tracks ever cached
- High CPU usage during eviction checks
- After 20 cached tracks, every new cache operation scans and re-sorts the entire map

**Remediation**:
```dart
/// Evicts oldest tracks if cache limits are exceeded
Future<void> _evictIfNeeded() async {
  // Check if eviction is needed first
  if (_cacheIndex.length <= maxCachedTracks) {
    final totalSize =
        _cacheIndex.values.fold<int>(0, (sum, i) => sum + i.sizeBytes);
    if (totalSize <= maxCacheSizeBytes) {
      return;
    }
  }

  // Sort by cache time (oldest first) - only when needed
  final sortedEntries = _cacheIndex.entries.toList()
    ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

  // Evict if count exceeded
  int idx = 0;
  while (_cacheIndex.length > maxCachedTracks && idx < sortedEntries.length) {
    final entry = sortedEntries[idx++];
    await _evictTrack(entry.key);
  }

  // Evict if size exceeded
  int totalSize = _cacheIndex.values.fold<int>(0, (sum, i) => sum + i.sizeBytes);
  idx = 0;
  while (totalSize > maxCacheSizeBytes && idx < sortedEntries.length) {
    final entry = sortedEntries[idx++];
    totalSize -= entry.value.sizeBytes;
    await _evictTrack(entry.key);
  }
}

/// Validates cache integrity and removes orphaned index entries
Future<void> validateAndRepairCache() async {
  await _ensureInitialized();

  // Remove index entries for files that no longer exist
  final keysToRemove = <String>[];
  for (final entry in _cacheIndex.entries) {
    if (!await File(entry.value.filePath).exists()) {
      keysToRemove.add(entry.key);
    }
  }

  for (final key in keysToRemove) {
    _cacheIndex.remove(key);
  }

  if (keysToRemove.isNotEmpty) {
    await _saveIndex();
  }
}
```

---

## Low-Severity Issues

### 10. CODE QUALITY LOW - Index Corruption Silent Handling
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/services/cache_service.dart`
**Lines**: 94-111
**Severity**: LOW
**Type**: Error Handling / Observability

**Issue**:
```dart
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
    } catch (_) {  // <-- Silent catch
      // Index corrupted, start fresh
      _cacheIndex.clear();
    }
  }
}
```

**Problem**:
- Any error during index loading is silently discarded
- Could hide JSON parsing errors, file I/O errors, or type casting errors
- No logging makes debugging impossible

**Impact**:
- Lost cache index means re-downloading all tracks
- No visibility into cache subsystem problems

**Remediation**:
```dart
Future<void> _loadIndex() async {
  final indexFile = File('${_cacheDir!.path}/index.json');
  if (await indexFile.exists()) {
    try {
      final content = await indexFile.readAsString();
      final List<dynamic> items = json.decode(content);
      for (final item in items) {
        try {
          final info = CachedTrackInfo.fromJson(item);
          // Verify file still exists
          if (await File(info.filePath).exists()) {
            _cacheIndex[info.trackId] = info;
          } else {
            print('Cache file missing for ${info.trackId}: ${info.filePath}');
          }
        } catch (e) {
          print('Failed to parse cache entry: $e');
        }
      }
    } catch (e) {
      print('Failed to load cache index: $e');
      // Index corrupted, start fresh
      _cacheIndex.clear();
    }
  }
}
```

---

### 11. CODE QUALITY LOW - Missing Null Check in PlaybackState.progress
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/providers/playback_provider.dart`
**Lines**: 34-39
**Severity**: LOW
**Type**: Null Safety

**Issue**:
```dart
double get progress {
  if (duration == null || duration!.inMilliseconds == 0) return 0;
  final raw = position.inMilliseconds / duration!.inMilliseconds;
  // Clamp to prevent values > 1.0 due to stream race conditions
  return raw.clamp(0.0, 1.0);
}
```

**Problem**:
- `position` is non-nullable, but what if playback hasn't started yet?
- `position` defaults to `Duration.zero` which is fine, but code doesn't document this assumption
- Race condition comment suggests values > 1.0 are possible despite clamping

**Impact**:
- Very minor, mostly a documentation issue
- Could cause subtle bugs if `position` ever becomes null

**Remediation**:
```dart
double get progress {
  // Return 0 if no track or no duration info
  if (duration == null || duration!.inMilliseconds == 0) return 0;

  // Clamp position to duration in case of race conditions
  final cappedPosition = position.inMilliseconds
      .clamp(0, duration!.inMilliseconds);

  final raw = cappedPosition / duration!.inMilliseconds;
  return raw.clamp(0.0, 1.0);
}
```

---

### 12. CODE QUALITY LOW - Inefficient String Sanitization
**File**: `/Users/rhillx/Code/MOM/robin-radio-2.0/robin_radio/lib/services/cache_service.dart`
**Lines**: 244-246
**Severity**: LOW
**Type**: Performance

**Issue**:
```dart
String _sanitizeFilename(String id) {
  return id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}
```

**Problem**:
- RegExp is compiled every call (though Flutter likely caches it)
- Unicode characters are replaced with underscores even if they're valid in filenames
- Doesn't handle edge cases like leading dots (hidden files on Unix)

**Impact**:
- Very minor performance impact
- Filenames may be longer than necessary

**Remediation**:
```dart
// Make regex static to avoid recompilation
static final _invalidCharsRegex = RegExp(r'[^a-zA-Z0-9_\-]');

String _sanitizeFilename(String id) {
  // Remove invalid characters and limit length
  final sanitized = id.replaceAll(_invalidCharsRegex, '_');

  // Avoid reserved filenames and leading dots
  if (sanitized.isEmpty || sanitized.startsWith('.')) {
    return 'cache_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Limit filename length (255 is typical max)
  return sanitized.length > 200 ? sanitized.substring(0, 200) : sanitized;
}
```

---

## Summary Table

| ID | File | Line | Severity | Type | Issue |
|----|------|------|----------|------|-------|
| 1 | storage_catalog_service.dart | 51-81 | HIGH | Error Handling | Uncaught Firebase exceptions in loadCatalog() |
| 2 | audio_service.dart | 166 | HIGH | Input Validation | Missing URL validation for cover images |
| 3 | cache_service.dart | 157-180 | HIGH | Error Handling | Uncaught HTTP exceptions with no cleanup |
| 4 | audio_service.dart | 135-140, 179 | HIGH | Null Safety | Fire-and-forget cache operations |
| 5 | connectivity_provider.dart | 16 | HIGH | Availability | Unsafe online assumption on plugin error |
| 6 | playback_provider.dart | 81-102 | MEDIUM | Concurrency | Race condition in state updates |
| 7 | catalog_provider.dart | 75-85 | MEDIUM | Input Validation | Missing bounds validation |
| 8 | catalog_provider.dart | 52-72 | MEDIUM | Error Handling | Generic error display & no retry |
| 9 | cache_service.dart | 69, 185-201 | MEDIUM | Memory Mgmt | Uncontrolled in-memory index growth |
| 10 | cache_service.dart | 94-111 | LOW | Error Handling | Silent index corruption handling |
| 11 | playback_provider.dart | 34-39 | LOW | Null Safety | Missing null check documentation |
| 12 | cache_service.dart | 244-246 | LOW | Performance | Inefficient regex compilation |

---

## Remediation Priority

**Immediate (This Sprint)**:
1. Issue #1 - Add try-catch to StorageCatalogService.loadCatalog()
2. Issue #3 - Add timeout and cleanup to CacheService.cacheTrack()
3. Issue #5 - Fix connectivity provider offline assumption

**Next Sprint**:
4. Issue #2 - Add URL validation for cover images
5. Issue #4 - Handle fire-and-forget cache operations
6. Issue #6 - Fix race condition in playback state updates

**Future**:
7. Issue #7 - Input validation in catalog methods
8. Issue #8 - Better error handling and retry UI
9. Issue #9 - Cache integrity validation
10. Issue #10 - Index error logging
11. Issue #11 - Progress property documentation
12. Issue #12 - Static regex compilation

---

## Compliance Notes

- **Null Safety**: Project uses sound null safety. Issues #4 and #11 relate to missing null assertions.
- **Error Handling**: Error handling is inconsistent. HIGH severity issues lack try-catch blocks; MEDIUM issues swallow errors silently.
- **Network Security**: URL validation is partially implemented (audio only, not images or metadata).
- **Resource Management**: Stream subscriptions are properly cancelled in playback_provider.dart; cache cleanup needs improvement.

---

## Next Steps

1. Address all HIGH-severity issues immediately to prevent crashes
2. Add comprehensive error handling to all Firebase/Network operations
3. Implement retry mechanisms for user-facing failures
4. Add detailed error logging for debugging
5. Perform integration testing with poor network conditions
6. Test offline mode thoroughly after fixes
