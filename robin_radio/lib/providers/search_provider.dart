import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'catalog_provider.dart';

/// State for search functionality
class SearchState {
  final String query;
  final List<SearchResult> results;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasResults => results.isNotEmpty;

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

/// Provider for the SearchService
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

/// Notifier for search state management
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _searchService;
  final Ref _ref;

  SearchNotifier(this._searchService, this._ref) : super(const SearchState());

  /// Performs a search with the given query
  void search(String query) {
    state = state.copyWith(query: query, isSearching: true);

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isSearching: false);
      return;
    }

    final catalogState = _ref.read(catalogProvider);

    final results = _searchService.search(
      query: query,
      artists: catalogState.artists,
      albums: catalogState.albums,
      tracks: catalogState.tracks,
    );

    state = state.copyWith(results: results, isSearching: false);
  }

  /// Clears the current search
  void clear() {
    state = const SearchState();
  }
}

/// Main search provider
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final service = ref.watch(searchServiceProvider);
  return SearchNotifier(service, ref);
});

/// Convenience provider for search results
final searchResultsProvider = Provider<List<SearchResult>>((ref) {
  return ref.watch(searchProvider).results;
});

/// Convenience provider for search query
final searchQueryProvider = Provider<String>((ref) {
  return ref.watch(searchProvider).query;
});
