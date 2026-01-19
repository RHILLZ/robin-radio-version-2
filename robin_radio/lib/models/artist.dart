import 'package:firebase_storage/firebase_storage.dart';

class Artist {
  final String id;
  final String name;
  final String storagePath;
  final int albumCount;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Artist(id: $id, name: $name, albums: $albumCount)';
}
