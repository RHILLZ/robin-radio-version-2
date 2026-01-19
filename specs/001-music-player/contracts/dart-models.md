# Dart Model Contracts

## Artist

```dart
class Artist {
  final String id;           // URL-safe slug
  final String name;         // Display name from folder
  final String storagePath;  // "Artist/{name}/"
  final int albumCount;      // Denormalized count

  const Artist({
    required this.id,
    required this.name,
    required this.storagePath,
    required this.albumCount,
  });

  factory Artist.fromStoragePrefix(Reference prefix, int albumCount) {
    final name = prefix.name;
    return Artist(
      id: Uri.encodeComponent(name),
      name: name,
      storagePath: prefix.fullPath,
      albumCount: albumCount,
    );
  }
}
```

## Album

```dart
class Album {
  final String id;           // URL-safe slug
  final String title;        // Album title from folder
  final String artistId;     // Reference to Artist
  final String artistName;   // Denormalized
  final String coverUrl;     // Download URL for cover image
  final String storagePath;  // "Artist/{artist}/{album}/"
  final int trackCount;      // Denormalized count

  const Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.coverUrl,
    required this.storagePath,
    required this.trackCount,
  });

  factory Album.fromStoragePrefix(
    Reference prefix,
    String artistName,
    String coverUrl,
    int trackCount,
  ) {
    final title = prefix.name;
    return Album(
      id: Uri.encodeComponent('$artistName/$title'),
      title: title,
      artistId: Uri.encodeComponent(artistName),
      artistName: artistName,
      coverUrl: coverUrl,
      storagePath: prefix.fullPath,
      trackCount: trackCount,
    );
  }
}
```

## Track

```dart
class Track {
  final String id;           // URL-safe slug
  final String title;        // Track title (sans number prefix)
  final String albumId;      // Reference to Album
  final String albumTitle;   // Denormalized
  final String artistName;   // Denormalized
  final int trackNumber;     // Extracted from filename
  final int? duration;       // Duration in seconds (nullable - from ID3)
  final String audioUrl;     // Download URL for streaming
  final String coverUrl;     // Album cover (inherited)
  final String storagePath;  // Full path to MP3

  const Track({
    required this.id,
    required this.title,
    required this.albumId,
    required this.albumTitle,
    required this.artistName,
    required this.trackNumber,
    this.duration,
    required this.audioUrl,
    required this.coverUrl,
    required this.storagePath,
  });

  factory Track.fromStorageItem(
    Reference item,
    String artistName,
    String albumTitle,
    String audioUrl,
    String coverUrl,
  ) {
    final filename = item.name;
    final parsed = _parseTrackFilename(filename);

    return Track(
      id: Uri.encodeComponent(item.fullPath),
      title: parsed.title,
      albumId: Uri.encodeComponent('$artistName/$albumTitle'),
      albumTitle: albumTitle,
      artistName: artistName,
      trackNumber: parsed.trackNumber,
      duration: null, // Populated later from audio metadata
      audioUrl: audioUrl,
      coverUrl: coverUrl,
      storagePath: item.fullPath,
    );
  }

  static ({int trackNumber, String title}) _parseTrackFilename(String filename) {
    // Pattern: "01 Track Title.mp3"
    final regex = RegExp(r'^(\d+)\s+(.+)\.mp3$', caseSensitive: false);
    final match = regex.firstMatch(filename);

    if (match != null) {
      return (
        trackNumber: int.parse(match.group(1)!),
        title: match.group(2)!,
      );
    }

    // Fallback for non-standard naming
    return (trackNumber: 0, title: filename.replaceAll('.mp3', ''));
  }
}
```

## PlaybackQueue

```dart
class PlaybackQueue {
  final List<Track> tracks;
  final int currentIndex;
  final bool isShuffled;
  final List<Track>? originalOrder;

  const PlaybackQueue({
    required this.tracks,
    required this.currentIndex,
    required this.isShuffled,
    this.originalOrder,
  });

  Track? get currentTrack =>
    tracks.isNotEmpty && currentIndex >= 0 && currentIndex < tracks.length
      ? tracks[currentIndex]
      : null;

  bool get hasNext => currentIndex < tracks.length - 1;
  bool get hasPrevious => currentIndex > 0;

  PlaybackQueue copyWith({
    List<Track>? tracks,
    int? currentIndex,
    bool? isShuffled,
    List<Track>? originalOrder,
  }) {
    return PlaybackQueue(
      tracks: tracks ?? this.tracks,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      originalOrder: originalOrder ?? this.originalOrder,
    );
  }

  /// Creates a shuffled queue starting from a random track
  factory PlaybackQueue.shuffled(List<Track> allTracks) {
    final shuffled = List<Track>.from(allTracks)..shuffle();
    return PlaybackQueue(
      tracks: shuffled,
      currentIndex: 0,
      isShuffled: true,
      originalOrder: allTracks,
    );
  }

  /// Creates an ordered queue for album playback
  factory PlaybackQueue.fromAlbum(List<Track> albumTracks, {int startIndex = 0}) {
    final sorted = List<Track>.from(albumTracks)
      ..sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
    return PlaybackQueue(
      tracks: sorted,
      currentIndex: startIndex,
      isShuffled: false,
    );
  }
}
```

## CachedTrack

```dart
class CachedTrack {
  final String trackId;
  final String localPath;
  final DateTime cachedAt;
  final int fileSize;

  const CachedTrack({
    required this.trackId,
    required this.localPath,
    required this.cachedAt,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() => {
    'trackId': trackId,
    'localPath': localPath,
    'cachedAt': cachedAt.toIso8601String(),
    'fileSize': fileSize,
  };

  factory CachedTrack.fromJson(Map<String, dynamic> json) {
    return CachedTrack(
      trackId: json['trackId'] as String,
      localPath: json['localPath'] as String,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      fileSize: json['fileSize'] as int,
    );
  }
}
```

## SearchResult

```dart
class SearchResult {
  final String type;  // 'artist', 'album', or 'track'
  final String id;
  final String title;
  final String? subtitle;  // Artist name for albums/tracks
  final String? imageUrl;  // Cover art URL
  final int score;         // Fuzzy match score (0-100)
  final dynamic item;      // Original Artist, Album, or Track

  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.score,
    required this.item,
  });
}
```
