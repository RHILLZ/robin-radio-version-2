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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedTrack &&
          runtimeType == other.runtimeType &&
          trackId == other.trackId;

  @override
  int get hashCode => trackId.hashCode;

  @override
  String toString() =>
      'CachedTrack(trackId: $trackId, size: $fileSize, cachedAt: $cachedAt)';
}
