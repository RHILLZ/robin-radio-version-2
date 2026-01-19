import 'package:fuzzywuzzy/fuzzywuzzy.dart';

import '../models/models.dart';

/// Service for searching artists, albums, and tracks with fuzzy matching
///
/// Uses fuzzywuzzy for typo-tolerant search so Mom can find music
/// even with imperfect spelling.
class SearchService {
  /// Minimum fuzzy match score to include in results (0-100)
  static const int _minScore = 40;

  /// Default maximum number of results to return
  static const int _defaultMaxResults = 20;

  /// Search across artists, albums, and tracks
  ///
  /// Returns a list of [SearchResult] objects sorted by relevance (score).
  /// Supports fuzzy matching for typo tolerance.
  List<SearchResult> search({
    required String query,
    required List<Artist> artists,
    required List<Album> albums,
    required List<Track> tracks,
    int? maxResults,
  }) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    final results = <SearchResult>[];

    // Search artists
    for (final artist in artists) {
      final score = _calculateScore(trimmedQuery, artist.name);
      if (score >= _minScore) {
        results.add(SearchResult.fromArtist(artist, score));
      }
    }

    // Search albums
    for (final album in albums) {
      final titleScore = _calculateScore(trimmedQuery, album.title);
      final artistScore = _calculateScore(trimmedQuery, album.artistName);
      final score = titleScore > artistScore ? titleScore : artistScore;
      if (score >= _minScore) {
        results.add(SearchResult.fromAlbum(album, score));
      }
    }

    // Search tracks
    for (final track in tracks) {
      final titleScore = _calculateScore(trimmedQuery, track.title);
      final artistScore = _calculateScore(trimmedQuery, track.artistName);
      final albumScore = _calculateScore(trimmedQuery, track.albumTitle);
      final score = [titleScore, artistScore, albumScore].reduce(
        (a, b) => a > b ? a : b,
      );
      if (score >= _minScore) {
        results.add(SearchResult.fromTrack(track, score));
      }
    }

    // Sort by score descending (best matches first)
    results.sort((a, b) => b.score.compareTo(a.score));

    // Limit results
    final limit = maxResults ?? _defaultMaxResults;
    if (results.length > limit) {
      return results.sublist(0, limit);
    }

    return results;
  }

  /// Calculate fuzzy match score between query and target string
  ///
  /// Returns a score from 0-100 where 100 is an exact match.
  /// Uses partial ratio for substring matching and token set ratio
  /// for word-order-independent matching.
  int _calculateScore(String query, String target) {
    final queryLower = query.toLowerCase();
    final targetLower = target.toLowerCase();

    // Exact match gets highest score
    if (targetLower == queryLower) {
      return 100;
    }

    // Contains match gets high score
    if (targetLower.contains(queryLower)) {
      return 95;
    }

    // Use fuzzywuzzy for fuzzy matching
    // Combine partial ratio (for substrings) and token set ratio (for word order)
    final partialScore = partialRatio(queryLower, targetLower);
    final tokenScore = tokenSetPartialRatio(queryLower, targetLower);

    // Take the better of the two scores
    return partialScore > tokenScore ? partialScore : tokenScore;
  }
}
