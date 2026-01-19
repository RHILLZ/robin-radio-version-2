import 'album.dart';
import 'artist.dart';
import 'track.dart';

/// Type of search result
enum SearchResultType {
  artist,
  album,
  track,
}

/// A unified search result that can represent an artist, album, or track
class SearchResult {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final String? coverUrl;
  final int score;

  // Original objects - only one will be non-null based on type
  final Artist? artist;
  final Album? album;
  final Track? track;

  const SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    this.coverUrl,
    required this.score,
    this.artist,
    this.album,
    this.track,
  });

  /// Create a search result from an Artist
  factory SearchResult.fromArtist(Artist artist, int score) {
    final albumText = artist.albumCount == 1 ? 'album' : 'albums';
    return SearchResult(
      type: SearchResultType.artist,
      title: artist.name,
      subtitle: '${artist.albumCount} $albumText',
      coverUrl: null,
      score: score,
      artist: artist,
    );
  }

  /// Create a search result from an Album
  factory SearchResult.fromAlbum(Album album, int score) {
    return SearchResult(
      type: SearchResultType.album,
      title: album.title,
      subtitle: album.artistName,
      coverUrl: album.coverUrl,
      score: score,
      album: album,
    );
  }

  /// Create a search result from a Track
  factory SearchResult.fromTrack(Track track, int score) {
    return SearchResult(
      type: SearchResultType.track,
      title: track.title,
      subtitle: '${track.artistName} • ${track.albumTitle}',
      coverUrl: track.coverUrl,
      score: score,
      track: track,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          title == other.title;

  @override
  int get hashCode => type.hashCode ^ title.hashCode;

  @override
  String toString() =>
      'SearchResult(type: $type, title: $title, score: $score)';
}
