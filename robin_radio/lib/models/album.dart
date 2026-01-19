import 'package:firebase_storage/firebase_storage.dart';

class Album {
  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final String coverUrl;
  final String storagePath;
  final int trackCount;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Album(id: $id, title: $title, artist: $artistName, tracks: $trackCount)';
}
