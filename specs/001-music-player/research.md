# Research: Music Player App

**Branch**: `001-music-player` | **Date**: 2026-01-18
**Purpose**: Resolve technical unknowns and establish best practices before implementation.

## 1. Audio Playback Stack

### Decision: just_audio + just_audio_background

**Rationale**:
- `just_audio` (v0.10.5) is the recommended Flutter audio package (Flutter Favorite, 4k+ likes)
- Purpose-built for music streaming with gapless playback, playlists, shuffle, and seeking
- Native support for Firebase Storage URLs (direct streaming)
- `just_audio_background` provides simple background playback + lock screen controls
- Minimal complexity compared to full `audio_service` wrapper

**Alternatives Considered**:
- `audioplayers`: Lighter but designed for sound effects, not music streaming
- `audio_service` alone: More complex, better for advanced queue management (overkill for single-user app)

**Key Packages**:
```yaml
just_audio: ^0.10.5
just_audio_background: ^0.1.0
```

## 2. Audio Caching & Offline Playback

### Decision: LockCachingAudioSource (built into just_audio)

**Rationale**:
- `just_audio` includes `LockCachingAudioSource` for streaming + caching in one
- Downloads while playing, prevents redundant downloads
- Works directly with Firebase Storage signed URLs
- No additional packages needed for basic offline playback
- Aligns with FR-014: cache last 10-20 tracks

**Alternatives Considered**:
- `dio` + `flutter_cache_manager`: More control but adds complexity
- Manual file downloads: Overkill for personal app scale

**Implementation Pattern**:
```dart
final audioSource = LockCachingAudioSource(
  Uri.parse(firebaseStorageUrl),
);
await player.setAudioSource(audioSource);
```

## 3. Firebase Integration

### Decision: Firestore for metadata + Firebase Storage direct URLs

**Rationale**:
- Firestore real-time listeners enable reactive UI updates
- Built-in offline persistence (configurable cache size)
- Firebase Storage `getDownloadURL()` for direct CDN streaming
- No intermediary server needed (simplicity principle)

**Data Structure**:
```
Firestore:
  albums/{albumId}
    - title, artistId, coverUrl, trackCount

  artists/{artistId}
    - name

  tracks/{trackId}
    - title, albumId, trackNumber, duration, audioUrl

Firebase Storage:
  /artists/{artist}/albums/{album}/
    - cover.jpg
    - 01-track.mp3, 02-track.mp3, ...
```

**Key Packages**:
```yaml
cloud_firestore: ^5.0.0
firebase_storage: ^12.0.0
firebase_core: ^3.0.0
```

## 4. Image Caching (Album Covers)

### Decision: cached_network_image

**Rationale**:
- Handles memory + disk caching automatically
- Simple API with placeholder and error widgets
- Default 100MB disk cache (sufficient for hundreds of albums)
- Works seamlessly with Firebase Storage URLs

**Key Package**:
```yaml
cached_network_image: ^3.4.0
```

**Implementation**:
```dart
CachedNetworkImage(
  imageUrl: album.coverUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.album),
)
```

## 5. Fuzzy Search

### Decision: fuzzywuzzy (client-side search)

**Rationale**:
- Client-side search is optimal for personal collection (hundreds, not thousands)
- Zero Firebase read costs for searches
- Works offline (PWA requirement)
- Instant results as user types (no network latency)
- `fuzzywuzzy` uses Levenshtein distance with multiple matching modes
- `extractTop()` returns ranked results with relevance scores

**Alternatives Considered**:
- Firestore queries: Adds latency, read costs, and doesn't support fuzzy matching natively
- Algolia/Elasticsearch: Overkill for personal app
- Custom Levenshtein: Reinventing the wheel

**Key Package**:
```yaml
fuzzywuzzy: ^1.2.0
```

**Implementation Pattern**:
```dart
// Load all albums/tracks on app init
// Search against in-memory list
final results = extractTop(
  query: userInput,
  choices: allSearchableItems,
  limit: 10,
  cutoff: 50, // minimum score threshold (0-100)
);
```

## 6. State Management

### Decision: Riverpod

**Rationale**:
- Works seamlessly with Firestore listeners
- Compile-time safety
- Easy testing with provider overrides
- Simpler than BLoC for this app's complexity
- `.select()` enables conditional offline UI

**Key Package**:
```yaml
flutter_riverpod: ^2.5.0
```

## 7. Offline Detection

### Decision: connectivity_plus

**Rationale**:
- Detect network state changes for offline indicator
- Cross-platform support (iOS, Android)
- Simple API for stream of connectivity changes

**Key Package**:
```yaml
connectivity_plus: ^6.0.0
```

## Summary: Final Tech Stack

| Component | Package | Version |
|-----------|---------|---------|
| Audio Player | just_audio | ^0.10.5 |
| Background Audio | just_audio_background | ^0.1.0 |
| Firebase Core | firebase_core | ^3.0.0 |
| Firestore | cloud_firestore | ^5.0.0 |
| Firebase Storage | firebase_storage | ^12.0.0 |
| Image Caching | cached_network_image | ^3.4.0 |
| Fuzzy Search | fuzzywuzzy | ^1.2.0 |
| State Management | flutter_riverpod | ^2.5.0 |
| Connectivity | connectivity_plus | ^6.0.0 |
| Testing | flutter_test, mockito | (bundled) |

## Resolved Unknowns

All NEEDS CLARIFICATION items from spec have been resolved:
- ✅ Audio streaming approach: just_audio + Firebase Storage URLs
- ✅ Background playback: just_audio_background
- ✅ Lock screen controls: Included with just_audio_background
- ✅ Offline caching: LockCachingAudioSource (built-in)
- ✅ Fuzzy search: fuzzywuzzy (client-side)
- ✅ State management: Riverpod
