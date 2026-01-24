import 'package:firebase_storage/firebase_storage.dart';

class Track {
  final String id;
  final String title;
  final String albumId;
  final String albumTitle;
  final String artistName;
  final int trackNumber;
  final int? duration;
  final String audioUrl;
  final String coverUrl;
  final String storagePath;

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
    String coverUrl, {
    int? duration,
  }) {
    final filename = item.name;
    final parsed = _parseTrackFilename(filename);

    return Track(
      id: Uri.encodeComponent(item.fullPath),
      title: parsed.title,
      albumId: Uri.encodeComponent('$artistName/$albumTitle'),
      albumTitle: albumTitle,
      artistName: artistName,
      trackNumber: parsed.trackNumber,
      duration: duration,
      audioUrl: audioUrl,
      coverUrl: coverUrl,
      storagePath: item.fullPath,
    );
  }

  static ({int trackNumber, String title}) _parseTrackFilename(String filename) {
    // Pattern: "01 Track Title.ext" for various audio formats
    final regex = RegExp(
      r'^(\d+)\s+(.+)\.(mp3|m4a|aac|wav|flac|ogg)$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(filename);

    if (match != null) {
      return (
        trackNumber: int.parse(match.group(1)!),
        title: match.group(2)!,
      );
    }

    // Fallback for non-standard naming - strip common audio extensions
    final cleanName = filename.replaceAll(
      RegExp(r'\.(mp3|m4a|aac|wav|flac|ogg)$', caseSensitive: false),
      '',
    );
    return (trackNumber: 0, title: cleanName);
  }

  Track copyWith({
    String? id,
    String? title,
    String? albumId,
    String? albumTitle,
    String? artistName,
    int? trackNumber,
    int? duration,
    String? audioUrl,
    String? coverUrl,
    String? storagePath,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      albumId: albumId ?? this.albumId,
      albumTitle: albumTitle ?? this.albumTitle,
      artistName: artistName ?? this.artistName,
      trackNumber: trackNumber ?? this.trackNumber,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      storagePath: storagePath ?? this.storagePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Track(id: $id, title: $title, album: $albumTitle, artist: $artistName)';
}
